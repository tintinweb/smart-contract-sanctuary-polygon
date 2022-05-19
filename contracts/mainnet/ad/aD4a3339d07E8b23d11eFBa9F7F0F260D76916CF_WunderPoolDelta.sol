// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./WunderVaultDelta.sol";

interface IPoolLauncher {
    function addPoolToMembersPools(address _pool, address _member) external;

    function removePoolFromMembersPools(address _pool, address _member)
        external;

    function wunderProposal() external view returns (address);
}

interface WunderProposal {
    function createProposal(
        address creator,
        uint256 proposalId,
        string memory title,
        string memory description,
        address[] memory contractAddresses,
        string[] memory actions,
        bytes[] memory params,
        uint256[] memory transactionValues,
        uint256 deadline
    ) external;

    function vote(
        uint256 _proposalId,
        uint256 _mode,
        address _voter
    ) external;

    function proposalExecutable(address _pool, uint256 _proposalId)
        external
        view
        returns (bool executable, string memory errorMessage);

    function setProposalExecuted(uint256 _proposalId) external;

    function getProposalTransactions(address _pool, uint256 _proposalId)
        external
        view
        returns (
            string[] memory actions,
            bytes[] memory params,
            uint256[] memory transactionValues,
            address[] memory contractAddresses
        );
}

contract WunderPoolDelta is WunderVaultDelta {
    address public wunderProposal;
    uint256[] public proposalIds;

    address[] public whiteList;
    mapping(address => bool) public whiteListLookup;

    address[] public members;
    mapping(address => bool) public memberLookup;

    string public name;
    address public launcherAddress;
    uint256 public entryBarrier;

    bool public poolClosed = false;

    modifier exceptPool() {
        require(msg.sender != address(this));
        _;
    }

    event NewProposal(
        uint256 indexed id,
        address indexed creator,
        string title
    );
    event Voted(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 mode
    );
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed executor,
        bytes[] result
    );
    event NewMember(address indexed memberAddress, uint256 stake);

    constructor(
        string memory _name,
        address _launcher,
        address _governanceToken,
        uint256 _entryBarrier,
        address _creator
    ) WunderVaultDelta(_governanceToken) {
        name = _name;
        launcherAddress = _launcher;
        entryBarrier = _entryBarrier;
        whiteList.push(_creator);
        whiteListLookup[_creator] = true;
        addToken(USDC, false, 0);
    }

    receive() external payable {}

    function createProposalForUser(
        address _user,
        string memory _title,
        string memory _description,
        address[] memory _contractAddresses,
        string[] memory _actions,
        bytes[] memory _params,
        uint256[] memory _transactionValues,
        uint256 _deadline,
        bytes memory _signature
    ) public {
        uint256 nextProposalId = proposalIds.length;
        proposalIds.push(nextProposalId);

        bytes32 message = prefixed(
            keccak256(
                abi.encode(
                    _user,
                    address(this),
                    _title,
                    _description,
                    _contractAddresses,
                    _actions,
                    _params,
                    _transactionValues,
                    _deadline,
                    nextProposalId
                )
            )
        );

        require(
            recoverSigner(message, _signature) == _user,
            "Invalid Signature"
        );
        require(isMember(_user), "Only Members can create Proposals");

        WunderProposal(IPoolLauncher(launcherAddress).wunderProposal())
            .createProposal(
                _user,
                nextProposalId,
                _title,
                _description,
                _contractAddresses,
                _actions,
                _params,
                _transactionValues,
                _deadline
            );

        emit NewProposal(nextProposalId, msg.sender, _title);
    }

    function voteForUser(
        address _user,
        uint256 _proposalId,
        uint256 _mode,
        bytes memory _signature
    ) public {
        bytes32 message = prefixed(
            keccak256(
                abi.encodePacked(_user, address(this), _proposalId, _mode)
            )
        );

        require(
            recoverSigner(message, _signature) == _user,
            "Invalid Signature"
        );
        WunderProposal(IPoolLauncher(launcherAddress).wunderProposal()).vote(
            _proposalId,
            _mode,
            _user
        );
        emit Voted(_proposalId, _user, _mode);
    }

    function executeProposal(uint256 _proposalId) public {
        poolClosed = true;
        (bool executable, string memory errorMessage) = WunderProposal(
            IPoolLauncher(launcherAddress).wunderProposal()
        ).proposalExecutable(address(this), _proposalId);
        require(executable, errorMessage);
        WunderProposal(IPoolLauncher(launcherAddress).wunderProposal())
            .setProposalExecuted(_proposalId);
        (
            string[] memory actions,
            bytes[] memory params,
            uint256[] memory transactionValues,
            address[] memory contractAddresses
        ) = WunderProposal(IPoolLauncher(launcherAddress).wunderProposal())
                .getProposalTransactions(address(this), _proposalId);
        bytes[] memory results = new bytes[](contractAddresses.length);

        for (uint256 index = 0; index < contractAddresses.length; index++) {
            address contractAddress = contractAddresses[index];
            bytes memory callData = bytes.concat(
                abi.encodeWithSignature(actions[index]),
                params[index]
            );

            bool success = false;
            bytes memory result;
            (success, result) = contractAddress.call{
                value: transactionValues[index]
            }(callData);
            require(success, "Execution failed");
            results[index] = result;
        }

        emit ProposalExecuted(_proposalId, msg.sender, results);
    }

    function joinForUser(uint256 _amount, address _user) public exceptPool {
        require(!poolClosed, "Pool Closed");
        require(
            (_amount >= entryBarrier && _amount >= governanceTokenPrice()),
            "Increase Stake"
        );
        require(
            ERC20Interface(USDC).transferFrom(_user, address(this), _amount),
            "USDC Transfer failed"
        );
        addMember(_user);
        _issueGovernanceTokens(_user, _amount);
        emit NewMember(_user, _amount);
    }

    function fundPool(uint256 amount) external exceptPool {
        require(!poolClosed, "Pool Closed");
        require(
            ERC20Interface(USDC).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "USDC Transfer failed"
        );
        _issueGovernanceTokens(msg.sender, amount);
    }

    function addMember(address _newMember) internal {
        require(!isMember(_newMember), "Already Member");
        require(isWhiteListed(_newMember), "Not On Whitelist");
        members.push(_newMember);
        memberLookup[_newMember] = true;
        IPoolLauncher(launcherAddress).addPoolToMembersPools(
            address(this),
            _newMember
        );
    }

    function addToWhiteListForUser(
        address _user,
        address _newMember,
        bytes memory _signature
    ) public {
        require(isMember(_user), "Only Members can Invite new Users");
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(_user, address(this), _newMember))
        );

        require(
            recoverSigner(message, _signature) == _user,
            "Invalid Signature"
        );

        if (!isWhiteListed(_newMember)) {
            whiteList.push(_newMember);
            whiteListLookup[_newMember] = true;
            IPoolLauncher(launcherAddress).addPoolToMembersPools(
                address(this),
                _newMember
            );
        }
    }

    function isMember(address _maybeMember) public view returns (bool) {
        return memberLookup[_maybeMember];
    }

    function isWhiteListed(address _user) public view returns (bool) {
        return whiteListLookup[_user];
    }

    function poolMembers() public view returns (address[] memory) {
        return members;
    }

    function getAllProposalIds() public view returns (uint256[] memory) {
        return proposalIds;
    }

    function liquidatePool() public onlyPool {
        _distributeFullBalanceOfAllTokensEvenly(members);
        _distributeAllMaticEvenly(members);
        _distributeAllNftsEvenly(members);
        _destroyGovernanceToken();
        selfdestruct(payable(msg.sender));
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20Interface {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

interface ERC721Interface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IGovernanceToken {
    function issue(address, uint256) external;

    function destroy() external;

    function price() external view returns (uint256);
}

contract WunderVaultDelta {
    address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address public governanceToken;

    address[] public ownedTokenAddresses;
    mapping(address => bool) public ownedTokenLookup;

    address[] public ownedNftAddresses;
    mapping(address => uint256[]) ownedNftLookup;

    modifier onlyPool() {
        require(
            msg.sender == address(this),
            "Not allowed. Try submitting a proposal"
        );
        _;
    }

    event TokenAdded(
        address indexed tokenAddress,
        bool _isERC721,
        uint256 _tokenId
    );
    event MaticWithdrawed(address indexed receiver, uint256 amount);
    event TokensWithdrawed(
        address indexed tokenAddress,
        address indexed receiver,
        uint256 amount
    );

    constructor(address _tokenAddress) {
        governanceToken = _tokenAddress;
    }

    function addToken(
        address _tokenAddress,
        bool _isERC721,
        uint256 _tokenId
    ) public {
        (, bytes memory nameData) = _tokenAddress.call(
            abi.encodeWithSignature("name()")
        );
        (, bytes memory symbolData) = _tokenAddress.call(
            abi.encodeWithSignature("symbol()")
        );
        (, bytes memory balanceData) = _tokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );

        require(nameData.length > 0, "Invalid Token");
        require(symbolData.length > 0, "Invalid Token");
        require(balanceData.length > 0, "Invalid Token");

        if (_isERC721) {
            if (ownedNftLookup[_tokenAddress].length == 0) {
                ownedNftAddresses.push(_tokenAddress);
            }
            if (
                ERC721Interface(_tokenAddress).ownerOf(_tokenId) ==
                address(this)
            ) {
                ownedNftLookup[_tokenAddress].push(_tokenId);
            }
        } else if (!ownedTokenLookup[_tokenAddress]) {
            ownedTokenAddresses.push(_tokenAddress);
            ownedTokenLookup[_tokenAddress] = true;
        }
        emit TokenAdded(_tokenAddress, _isERC721, _tokenId);
    }

    function removeNft(address _tokenAddress, uint256 _tokenId) public {
        if (ERC721Interface(_tokenAddress).ownerOf(_tokenId) != address(this)) {
            for (uint256 i = 0; i < ownedNftLookup[_tokenAddress].length; i++) {
                if (ownedNftLookup[_tokenAddress][i] == _tokenId) {
                    delete ownedNftLookup[_tokenAddress][i];
                    ownedNftLookup[_tokenAddress][i] = ownedNftLookup[
                        _tokenAddress
                    ][ownedNftLookup[_tokenAddress].length - 1];
                    ownedNftLookup[_tokenAddress].pop();
                }
            }
        }
    }

    function getOwnedTokenAddresses() public view returns (address[] memory) {
        return ownedTokenAddresses;
    }

    function getOwnedNftAddresses() public view returns (address[] memory) {
        return ownedNftAddresses;
    }

    function getOwnedNftTokenIds(address _contractAddress)
        public
        view
        returns (uint256[] memory)
    {
        return ownedNftLookup[_contractAddress];
    }

    function _distributeNftsEvenly(
        address _tokenAddress,
        address[] memory _receivers
    ) public onlyPool {
        for (uint256 i = 0; i < ownedNftLookup[_tokenAddress].length; i++) {
            if (
                ERC721Interface(_tokenAddress).ownerOf(
                    ownedNftLookup[_tokenAddress][i]
                ) == address(this)
            ) {
                uint256 sum = 0;
                uint256 randomNumber = uint256(
                    keccak256(
                        abi.encode(
                            _tokenAddress,
                            ownedNftLookup[_tokenAddress][i],
                            block.timestamp
                        )
                    )
                ) % totalGovernanceTokens();
                for (uint256 j = 0; j < _receivers.length; j++) {
                    sum += governanceTokensOf(_receivers[j]);
                    if (sum >= randomNumber) {
                        (bool success, ) = _tokenAddress.call(
                            abi.encodeWithSignature(
                                "transferFrom(address,address,uint256)",
                                address(this),
                                _receivers[j],
                                ownedNftLookup[_tokenAddress][i]
                            )
                        );
                        require(success, "Transfer failed");
                        break;
                    }
                }
            }
        }
    }

    function _distributeAllNftsEvenly(address[] memory _receivers)
        public
        onlyPool
    {
        for (uint256 i = 0; i < ownedNftAddresses.length; i++) {
            _distributeNftsEvenly(ownedNftAddresses[i], _receivers);
        }
    }

    function _distributeSomeBalanceOfTokenEvenly(
        address _tokenAddress,
        address[] memory _receivers,
        uint256 _amount
    ) public onlyPool {
        for (uint256 index = 0; index < _receivers.length; index++) {
            _withdrawTokens(
                _tokenAddress,
                _receivers[index],
                (_amount * governanceTokensOf(_receivers[index])) /
                    totalGovernanceTokens()
            );
        }
    }

    function _distributeFullBalanceOfTokenEvenly(
        address _tokenAddress,
        address[] memory _receivers
    ) public onlyPool {
        uint256 balance = ERC20Interface(_tokenAddress).balanceOf(
            address(this)
        );

        _distributeSomeBalanceOfTokenEvenly(_tokenAddress, _receivers, balance);
    }

    function _distributeFullBalanceOfAllTokensEvenly(
        address[] memory _receivers
    ) public onlyPool {
        for (uint256 index = 0; index < ownedTokenAddresses.length; index++) {
            _distributeFullBalanceOfTokenEvenly(
                ownedTokenAddresses[index],
                _receivers
            );
        }
    }

    function _distributeMaticEvenly(
        address[] memory _receivers,
        uint256 _amount
    ) public onlyPool {
        for (uint256 index = 0; index < _receivers.length; index++) {
            _withdrawMatic(
                _receivers[index],
                (_amount * governanceTokensOf(_receivers[index])) /
                    totalGovernanceTokens()
            );
        }
    }

    function _distributeAllMaticEvenly(address[] memory _receivers)
        public
        onlyPool
    {
        uint256 balance = address(this).balance;
        _distributeMaticEvenly(_receivers, balance);
    }

    function _withdrawTokens(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) public onlyPool {
        if (_amount > 0) {
            uint256 balance = ERC20Interface(_tokenAddress).balanceOf(
                address(this)
            );
            require(balance >= _amount, "Amount exceeds balance");
            require(
                ERC20Interface(_tokenAddress).transfer(_receiver, _amount),
                "Withdraw Failed"
            );
            emit TokensWithdrawed(_tokenAddress, _receiver, _amount);
        }
    }

    function _withdrawMatic(address _receiver, uint256 _amount)
        public
        onlyPool
    {
        if (_amount > 0) {
            require(address(this).balance >= _amount, "Amount exceeds balance");
            payable(_receiver).transfer(_amount);
            emit MaticWithdrawed(_receiver, _amount);
        }
    }

    function _issueGovernanceTokens(address _newUser, uint256 _value) internal {
        IGovernanceToken(governanceToken).issue(
            _newUser,
            _value / governanceTokenPrice()
        );
    }

    function governanceTokensOf(address _user)
        public
        view
        returns (uint256 balance)
    {
        return ERC20Interface(governanceToken).balanceOf(_user);
    }

    function totalGovernanceTokens() public view returns (uint256 balance) {
        return ERC20Interface(governanceToken).totalSupply();
    }

    function governanceTokenPrice() public view returns (uint256 price) {
        return IGovernanceToken(governanceToken).price();
    }

    function _destroyGovernanceToken() internal {
        IGovernanceToken(governanceToken).destroy();
    }
}