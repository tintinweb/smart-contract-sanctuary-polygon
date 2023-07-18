/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/DaoClub.sol


pragma solidity ^0.8.9;



contract DAOClub is Ownable {
    struct CandidateProfile {
        string profileURI;
        address walletAddress;
        address[] sponsors;
        uint256 filingTime;
        string username;
    }

    struct CandidateInfo {
        bool isMember;
        bool isBlacklisted;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        mapping(address => bool) hasVoted;
        // uint256 score;
    }

    mapping(address => CandidateProfile) public candidateProfiles;
    mapping(address => CandidateInfo) public candidateInfos;
    mapping(string => bool) private usernames;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    mapping(address => uint256) public powerPoints;
    address public treasuryWallet;
    uint256 public votingPeriod = 2 minutes;
    uint256 public totalMembers;
    uint256 public airdropStatus; // 0: Airdrop not started, 1: Airdrop in first phase, 2: Airdrop in second phase, 3: Airdrop in third phase, 4: Airdrop ended
    address[] public daoMembers;

    IERC20 public tokenContract;

    event ProfileFiled(address indexed candidateAddress, string profileURI, string username);
    event VoteCasted(address indexed voter, address indexed candidateAddress, bool inSupport);
    event TokensTransferred(address indexed recipient, uint256 amount);
    event SponsorRewarded(address indexed sponsor, uint256 points);
    event DaoMemberAdded(address indexed member);

    constructor(address _treasuryWallet, address _tokenContract) {
        tokenContract = IERC20(_tokenContract);

        candidateInfos[msg.sender].isMember = true;
        treasuryWallet = _treasuryWallet;
        whitelist[msg.sender] = true; // treasury wallet as the first DAO member and whitelist it
        daoMembers.push(msg.sender);
        totalMembers++;
        emit DaoMemberAdded(msg.sender);
    }

    function fileProfile(
        string memory _profileURI,
        string memory _username,
        address[] memory _sponsors
    ) external {
        require(candidateProfiles[msg.sender].walletAddress == address(0), "Profile already filed.");
        require(!usernames[_username], "Username already taken.");

        // Validate and add sponsors
        for (uint256 i = 0; i < _sponsors.length; i++) {
            address sponsor = _sponsors[i];
            require(candidateInfos[sponsor].isMember, "Invalid sponsor.");
            require(sponsor != msg.sender, "sender can't be the sponsor.");
            candidateProfiles[msg.sender].sponsors.push(sponsor);
        }

        candidateProfiles[msg.sender] = CandidateProfile({
            profileURI: _profileURI,
            walletAddress: msg.sender,
            sponsors: candidateProfiles[msg.sender].sponsors,
            filingTime: block.timestamp,
            username: _username
        });

        usernames[_username] = true;

        emit ProfileFiled(msg.sender, _profileURI, _username);
    }

    function addToWhitelist(address _account) external onlyOwner {
        whitelist[_account] = true;
    }

    function addToBlacklist(address _account) external onlyOwner {
        blacklist[_account] = true;
    }

    function removeFromWhitelist(address _account) external onlyOwner {
        whitelist[_account] = false;
    }

    function removeFromBlacklist(address _account) external onlyOwner {
        blacklist[_account] = false;
    }

    function castVote(address _candidateAddress, bool _inSupport) external {
        require(candidateProfiles[_candidateAddress].walletAddress != address(0), "Candidate not found.");
        require(!candidateInfos[_candidateAddress].isMember, "Candidate is already a member.");
        require(candidateInfos[msg.sender].isMember, "Voter is not a member.");
        require(!candidateInfos[_candidateAddress].hasVoted[msg.sender], "Already voted.");
        require(!blacklist[msg.sender], "Voter account is blacklisted.");

        require(
            block.timestamp <= candidateProfiles[_candidateAddress].filingTime + votingPeriod,
            "Voting period has ended."
        );

        candidateInfos[_candidateAddress].hasVoted[msg.sender] = true;

        if (_inSupport) {
            candidateInfos[_candidateAddress].voteCountFor += powerPoints[msg.sender];
        } else {
            candidateInfos[_candidateAddress].voteCountAgainst += powerPoints[msg.sender];
        }

        powerPoints[msg.sender]++;

        emit VoteCasted(msg.sender, _candidateAddress, _inSupport);
    }

    function determineMembershipStatus(address _candidateAddress) external {
        require(candidateProfiles[_candidateAddress].walletAddress != address(0), "Candidate not found.");
        require(!candidateInfos[_candidateAddress].isMember, "Candidate is already a member.");

        require(
            block.timestamp > candidateProfiles[_candidateAddress].filingTime + votingPeriod,
            "Voting period has not ended yet."
        );

        if (
            candidateInfos[_candidateAddress].voteCountFor > candidateInfos[_candidateAddress].voteCountAgainst
        ) {
            candidateInfos[_candidateAddress].isMember = true;
            totalMembers++;
            daoMembers.push(_candidateAddress);

            emit DaoMemberAdded(_candidateAddress);
            whitelist[_candidateAddress] = true;
            address[] memory sponsors = candidateProfiles[msg.sender].sponsors;
            for (uint256 i = 0; i < sponsors.length; i++) {
                address sponsor = sponsors[i];
                powerPoints[sponsor] += 100;
                emit SponsorRewarded(sponsor, 100);
            }
            // Transfer tokens based on airdrop rules
            if (airdropStatus == 0) {
                if (totalMembers <= 100) {
                    // First phase: 10,000 tokens for the first 100 members
                    transferTokens(_candidateAddress, 10000*10**18);
                } else {
                    airdropStatus = 1;
                    transferTokens(_candidateAddress, 0);
                }
            } else if (airdropStatus == 1) {
                if (totalMembers <= 1100) {
                    // Second phase: 5,000 tokens for the next 1,000 members
                    transferTokens(_candidateAddress, 5000*10**18);
                } else {
                    airdropStatus = 2;
                    transferTokens(_candidateAddress, 0);
                }
            } else if (airdropStatus == 2) {
                if (totalMembers <= 11100) {
                    // Third phase: 2,500 tokens for the next 10,000 members
                    transferTokens(_candidateAddress, 2500*10**18);
                } else {
                    airdropStatus = 3;
                    transferTokens(_candidateAddress, 0);
                }
            } else {
                // Airdrop ended, no more tokens to transfer
                transferTokens(_candidateAddress, 0);
            }
        } else {
            candidateInfos[_candidateAddress].isBlacklisted = true;
        }
    }

    function transferTokens(address _recipient, uint256 _amount) internal {
        // I'll implement token transfer logic here
        if(_amount > 0) {
            tokenContract.transferFrom(treasuryWallet, _recipient, _amount);
            emit TokensTransferred(_recipient, _amount);
        }
    }

    function getDaoMembers() external view returns (address[] memory) {
        return daoMembers;
    }

    function setVotingPeriod(uint256 _votingPeriod) external onlyOwner {
        votingPeriod = _votingPeriod;
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        whitelist[_treasuryWallet] = false; // treasury wallet as the first DAO member and whitelist it
        // remove the previous wallet from dao members array
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == treasuryWallet) {
                daoMembers[i] = _treasuryWallet;
                break;
            }
        }
        treasuryWallet = _treasuryWallet;

    }

    function setAirdropStatus(uint256 _airdropStatus) external onlyOwner {
        airdropStatus = _airdropStatus;
    }

    // function deleteDaoMember(address _member) external onlyOwner {
    //     require(_member != treasuryWallet, "Cannot delete treasury wallet.");
    //     require(candidateInfos[_member].isMember, "Not a member.");
    //     candidateInfos[_member].isMember = false;
    //     totalMembers--;
    //     for (uint256 i = 0; i < daoMembers.length; i++) {
    //         if (daoMembers[i] == _member) {
    //             delete daoMembers[i];
    //             break;
    //         }
    //     }
    // }

    function addPowerPoints(address _account, uint256 _points) external onlyOwner {
        powerPoints[_account] += _points;
    }

    function isMember(address _account) external view returns (bool) {
        return candidateInfos[_account].isMember;
    }

}