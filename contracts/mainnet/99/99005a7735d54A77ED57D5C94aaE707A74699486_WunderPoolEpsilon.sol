// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./WunderVaultEpsilon.sol";

interface IPoolLauncher {
    function addPoolToMembersPools(address _pool, address _member) external;

    function wunderProposal() external view returns (address);

    function poolConfig() external view returns (address);
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
        uint256[] memory transactionValues
    ) external;

    function createJoinProposal(
        address user,
        uint256 proposalId,
        string memory title,
        string memory description,
        uint256 amount,
        uint256 governanceTokens,
        address paymentToken,
        address governanceToken
    ) external;

    function vote(
        uint256 proposalId,
        uint256 mode,
        address voter
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

interface PoolConfig {
    function setupPool(
        address pool,
        uint256 minInvest,
        uint256 maxInvest,
        uint256 maxMembers,
        uint8 votingThreshold,
        uint256 votingTime,
        uint256 minYesVoters
    ) external;

    function memberCanJoin(
        address pool,
        uint256 amount,
        uint256 invested,
        uint256 tokenPrice,
        uint256 members
    ) external view returns (bool, string memory);

    function maxInvest(address) external view returns (uint256);
}

contract WunderPoolEpsilon is WunderVaultEpsilon {
    uint256[] internal proposalIds;

    mapping(bytes32 => uint256) internal _secretWhiteList;
    mapping(bytes32 => bool) internal _secretsUsed;

    mapping(address => bool) internal whiteList;
    mapping(address => uint256) public investOfUser;

    address[] internal members;
    mapping(address => bool) internal memberLookup;

    string public name;
    address public launcherAddress;

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
        address _creator,
        address[] memory _members,
        uint256 _amount
    ) WunderVaultEpsilon(_governanceToken) {
        name = _name;
        launcherAddress = _launcher;
        investOfUser[_creator] = _amount;
        members.push(_creator);
        memberLookup[_creator] = true;
        addToken(USDC, false, 0);
        for (uint256 i = 0; i < _members.length; i++) {
            whiteList[_members[i]] = true;
        }
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
                    nextProposalId
                )
            )
        );

        reqSig(message, _signature, _user);
        reqMem(_user);

        ProposalModule().createProposal(
            _user,
            nextProposalId,
            _title,
            _description,
            _contractAddresses,
            _actions,
            _params,
            _transactionValues
        );

        emit NewProposal(nextProposalId, _user, _title);
    }

    function createJoinProposal(
        address _user,
        string memory _title,
        string memory _description,
        uint256 _amount,
        uint256 _governanceTokens
    ) public {
        uint256 nextProposalId = proposalIds.length;
        proposalIds.push(nextProposalId);

        ProposalModule().createJoinProposal(
            _user,
            nextProposalId,
            _title,
            _description,
            _amount,
            _governanceTokens,
            USDC,
            governanceToken
        );

        emit NewProposal(nextProposalId, _user, _title);
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

        reqSig(message, _signature, _user);
        ProposalModule().vote(_proposalId, _mode, _user);
        emit Voted(_proposalId, _user, _mode);
    }

    function executeProposal(uint256 _proposalId) public {
        poolClosed = true;
        (bool executable, string memory errorMessage) = ProposalModule()
            .proposalExecutable(address(this), _proposalId);
        require(executable, errorMessage);
        ProposalModule().setProposalExecuted(_proposalId);
        (
            string[] memory actions,
            bytes[] memory params,
            uint256[] memory transactionValues,
            address[] memory contractAddresses
        ) = ProposalModule().getProposalTransactions(
                address(this),
                _proposalId
            );
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

    function joinForUser(
        uint256 _amount,
        address _user,
        string memory _secret
    ) public exceptPool {
        if (governanceTokensOf(_user) <= 0) {
            require(!poolClosed, "Pool Closed");
            if (_secretWhiteList[keccak256(bytes(_secret))] > 0) {
                _secretWhiteList[keccak256(bytes(_secret))] -= 1;
            } else {
                require(isWhiteListed(_user), "Not On Whitelist");
            }

            reqJoin(_amount, _user);
            reqTra(USDC, _user, address(this), _amount);
            investOfUser[_user] += _amount;
            _issueGovernanceTokens(_user, _amount / governanceTokenPrice());
        }
        _addMember(_user);
        emit NewMember(_user, _amount);
    }

    function fundPool(uint256 _amount) external exceptPool {
        require(!poolClosed, "Pool Closed");
        require(
            investOfUser[msg.sender] + _amount <=
                ConfigModule().maxInvest(address(this)),
            "maxInvest reached"
        );
        investOfUser[msg.sender] += _amount;
        reqTra(USDC, msg.sender, address(this), _amount);
        _issueGovernanceTokens(msg.sender, _amount / governanceTokenPrice());
    }

    function addMember(address _newMember) public {
        require(msg.sender == address(this));
        _addMember(_newMember);
    }

    function _addMember(address _newMember) internal {
        require(!isMember(_newMember), "Already Member");
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
        reqMem(_user);
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(_user, address(this), _newMember))
        );

        reqSig(message, _signature, _user);

        if (!isWhiteListed(_newMember)) {
            whiteList[_newMember] = true;
            IPoolLauncher(launcherAddress).addPoolToMembersPools(
                address(this),
                _newMember
            );
        }
    }

    function addToWhiteListWithSecret(
        address _user,
        bytes32 _hashedSecret,
        uint256 _validForCount,
        bytes memory _signature
    ) public {
        reqMem(_user);
        require(!_secretsUsed[_hashedSecret]);
        bytes32 message = prefixed(
            keccak256(
                abi.encodePacked(
                    _user,
                    address(this),
                    _hashedSecret,
                    _validForCount
                )
            )
        );

        reqSig(message, _signature, _user);
        _secretWhiteList[_hashedSecret] = _validForCount;
        _secretsUsed[_hashedSecret] = true;
    }

    function isMember(address _maybeMember) public view returns (bool) {
        return memberLookup[_maybeMember];
    }

    function isWhiteListed(address _user) public view returns (bool) {
        return whiteList[_user];
    }

    function poolMembers() public view returns (address[] memory) {
        return members;
    }

    function getAllProposalIds() public view returns (uint256[] memory) {
        return proposalIds;
    }

    function liquidatePool() public {
        require(msg.sender == address(this));
        _distributeFullBalanceOfAllTokensEvenly(members);
        _distributeAllMaticEvenly(members);
        _distributeAllNftsEvenly(members);
        _destroyGovernanceToken();
        selfdestruct(payable(members[0]));
    }

    function ConfigModule() internal view returns (PoolConfig) {
        return PoolConfig(IPoolLauncher(launcherAddress).poolConfig());
    }

    function ProposalModule() internal view returns (WunderProposal) {
        return WunderProposal(IPoolLauncher(launcherAddress).wunderProposal());
    }

    function reqSig(
        bytes32 _msg,
        bytes memory _sig,
        address _usr
    ) internal pure {
        require(recoverSigner(_msg, _sig) == _usr, "Invalid Signature");
    }

    function reqMem(address _usr) internal view {
        require(isMember(_usr), "Not a Member");
    }

    function reqJoin(uint256 _amount, address _user) internal view {
        (bool canJoin, string memory errMsg) = ConfigModule().memberCanJoin(
            address(this),
            _amount,
            investOfUser[_user],
            governanceTokenPrice(),
            members.length
        );
        require(canJoin, errMsg);
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
    function setPoolAddress(address _poolAddress) external;

    function issue(address, uint256) external;

    function destroy() external;

    function price() external view returns (uint256);
}

contract WunderVaultEpsilon {
    address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address public governanceToken;

    address[] internal ownedTokenAddresses;
    mapping(address => bool) public ownedTokenLookup;

    address[] internal ownedNftAddresses;
    mapping(address => uint256[]) ownedNftLookup;

    event TokenAdded(
        address indexed tokenAddress,
        bool _isERC721,
        uint256 _tokenId
    );
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
    ) internal {
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

    function _distributeAllNftsEvenly(address[] memory _receivers) internal {
        for (uint256 i = 0; i < ownedNftAddresses.length; i++) {
            _distributeNftsEvenly(ownedNftAddresses[i], _receivers);
        }
    }

    function _distributeSomeBalanceOfTokenEvenly(
        address _tokenAddress,
        address[] memory _receivers,
        uint256 _amount
    ) internal {
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
    ) internal {
        uint256 balance = ERC20Interface(_tokenAddress).balanceOf(
            address(this)
        );

        _distributeSomeBalanceOfTokenEvenly(_tokenAddress, _receivers, balance);
    }

    function _distributeFullBalanceOfAllTokensEvenly(
        address[] memory _receivers
    ) internal {
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
    ) internal {
        for (uint256 index = 0; index < _receivers.length; index++) {
            _withdrawMatic(
                _receivers[index],
                (_amount * governanceTokensOf(_receivers[index])) /
                    totalGovernanceTokens()
            );
        }
    }

    function _distributeAllMaticEvenly(address[] memory _receivers) internal {
        uint256 balance = address(this).balance;
        _distributeMaticEvenly(_receivers, balance);
    }

    function _withdrawTokens(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(ERC20Interface(_tokenAddress).transfer(_receiver, _amount));
            emit TokensWithdrawed(_tokenAddress, _receiver, _amount);
        }
    }

    function _withdrawMatic(address _receiver, uint256 _amount) internal {
        if (_amount > 0) {
            payable(_receiver).transfer(_amount);
            emit TokensWithdrawed(address(0), _receiver, _amount);
        }
    }

    function _issueGovernanceTokens(address _newUser, uint256 _amount)
        internal
    {
        IGovernanceToken(governanceToken).issue(_newUser, _amount);
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

    function reqTra(
        address token,
        address from,
        address to,
        uint256 amount
    ) public {
        require(
            ERC20Interface(token).transferFrom(from, to, amount),
            "Transfer Failed"
        );
    }
}