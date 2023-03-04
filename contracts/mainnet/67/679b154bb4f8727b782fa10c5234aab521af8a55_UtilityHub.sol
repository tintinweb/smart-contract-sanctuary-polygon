/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

pragma solidity ^0.8.17;

/*
                 --.
               .*%@*=.
              .##++=***+:
            :+*#%#**#*#%#+.
          .+##+-#%###%%%%%+
        :+#+:..-#%%%%%#*+++
 .::---=##++*#%%%%#%%##*==*
  :#%%%%%%%%%%%%%%%%####+*#-
 -*==#%%%%%%%%%#***#####%##*.
.: .=%%%%%%%%#****%%###%%%#**.
   :-=%%%%%%*#**#%%%#%#%%%%#%*:
     #%%%%%%+**%##%#=#%%%%%%%%*:
     :.--+###*+-.::   *#%%#%%%#=.
        .****.:::::::+#%%%%%%%#++
...::::-*#**==++++++*%%%%%%%%%%##*=.
.::----=##*===++++++*%%%%%%%%%%%%###*:
::::::=##=----==++++*%%%%%%%%%%%%%%%#*.
:-===*##+.     ..-=++*#%%%%%%%%%%%%*+.
 .:-**+.            ...:--====-::..      */

interface IERC20  {
    function mint(address user, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC1155 {
  function mint(address to, uint256 tokenId, uint256 amount) external;
  function burnFrom(address from, uint256 amount) external;
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;
}

interface IUtilityManager {
    function balanceOf(address owner) external view returns (uint256 balance);
    function rewardableBalanceOf(address user) external view returns(uint256);
}

interface ITokenomicEq {
    function getDispensableFrom(uint256 day, uint256 from, uint256 bal) external view returns(uint256);
}

contract UtilityHub is Ownable {

    error NoRewardsClaimable();
    error NotManagingContract();

    struct UtilityToken {
        address addr;
        address manager;
        address tokenomicEq;
        uint8 stake;
        uint8 issuanceType; // mint/transfer
        uint32 tokenType; // erc20/erc1155
        uint256 tokenId; //for erc1155
        uint256 start;
        uint256 end;
    }

    struct UserData {
        uint256 rewards;
        uint256 lastUpdate;
    }

    mapping(uint256 => UtilityToken) public utilityTokens;

    // user => tokenIndex => user data
    mapping(address => mapping(uint256 => UserData)) public userData;

    uint256 private _utilityTokenCount;

    /**
     * Owner
     */

    function addNewToken(
        address manager_,//the ERC721 contract
        address address_,//the ERC20/ERC1155 contract
        address tokenomicEq_,//the tokenomic equation
        uint256 start_,
        uint256 end_,
        uint256 tokenType_, // erc20/erc1155
        uint256 tokenId_,
        uint256 issuanceType_, // mint/transfer
        uint256 stake_
    ) external onlyOwner {
        require(start_ > 0);
        require(start_ < end_);
        require(manager_ != address(0));
        require(address_ != address(0));
        require(tokenomicEq_ != address(0));
        require(tokenType_ == 20 || tokenType_ == 1155);
        require(issuanceType_ <= 1);
        require(stake_ <= 2);

        utilityTokens[_utilityTokenCount++] = UtilityToken({
            addr: address_,
            manager: manager_,
            tokenomicEq: tokenomicEq_,
            stake: uint8(stake_),
            issuanceType: uint8(issuanceType_),
            tokenType: uint32(tokenType_),
            tokenId: tokenId_,
            start: start_,
            end: end_
        });
    }

    function removeToken(uint256 tokenIndex_) external onlyOwner {
        delete utilityTokens[tokenIndex_];
    }

    /**
     * This is used to prevent holders from claiming unearned tachyon and needs to be called whenever
     * a transfer is initiated from/to the users wallet
     */
    function updateUserToken(address user_, uint256 tokenIndex_, uint256 totalClaimable_) external onlyOwner {

        UserData storage ud = userData[user_][tokenIndex_];
        ud.rewards = totalClaimable_;
        ud.lastUpdate = block.timestamp;
    }

    /**
     * User interactions
     */

    function getTotalClaimable(address user_, uint256 tokenIndex_) public view returns(uint256 rewards, bool claimable) {

        UtilityToken memory utilityToken = utilityTokens[tokenIndex_];

        uint256 time = _getTime(utilityToken.start, utilityToken.end);

        if (time > 0) {

            UserData memory ud = userData[user_][tokenIndex_];

            rewards = ud.rewards;

            uint256 userLastUpdate = _max(ud.lastUpdate, utilityToken.start);
            uint256 delta = time - userLastUpdate;

            if (userLastUpdate > 0 && delta > 0) {

                uint256 from;

                if (ud.lastUpdate > 0) {
                    from = ud.lastUpdate - utilityToken.start;
                }
                else {
                    from = block.timestamp - utilityToken.start;
                }

                if (from >= 86400) {
                    if (delta >= 86400) claimable = true;
                    from = from / 86400;
                }

                IUtilityManager utilityMgr = IUtilityManager(utilityToken.manager);

                uint256 bal;

                if (utilityToken.stake == uint8(0)) {
                    bal = utilityMgr.rewardableBalanceOf(user_);
                }
                else if (utilityToken.stake == uint8(1)) {
                    bal = utilityMgr.balanceOf(user_);
                }
                else if (utilityToken.stake == uint8(2)) {
                    bal = utilityMgr.balanceOf(user_) - utilityMgr.rewardableBalanceOf(user_);
                }
                uint256 _until = from + (delta / 86400);
                if (_until != from) {
                    ITokenomicEq tokenomicEq = ITokenomicEq(utilityToken.tokenomicEq);
                    rewards += tokenomicEq.getDispensableFrom(_until, from, bal);
                }
            }
        }
    }

    function getUserData(address user_, uint256 tokenIndex_) external view returns(uint256,uint256) {
        UserData storage ud = userData[user_][tokenIndex_];
        return (ud.lastUpdate, ud.rewards);
    }

    function getReward(address user_, uint256 tokenIndex_) external {

        UtilityToken memory utilityToken = utilityTokens[tokenIndex_];

        if (msg.sender != address(utilityToken.manager)) revert NotManagingContract();

        UserData storage ud = userData[user_][tokenIndex_];

        uint256 time = _getTime(utilityToken.start, utilityToken.end);

        uint256 rewards;
        bool claimable;

        if (time > 0) {

            (rewards, claimable) = getTotalClaimable(user_, tokenIndex_);

            if (claimable) {
                ud.rewards = rewards;
            }
            if (ud.lastUpdate < time) {
                ud.lastUpdate = time;
            }
        }

        uint256 amount = ud.rewards;

        if (amount == 0 || !claimable) revert NoRewardsClaimable();

        uint256 tokenType = uint256(utilityToken.tokenType);
        ud.rewards = 0;
        if (tokenType == 20) {
            if (utilityToken.issuanceType == 0) // mint
                IERC20(utilityToken.addr).mint(user_, amount);
            else
                IERC20(utilityToken.addr).transfer(user_, amount);
        }
        else if (tokenType == 1155) {
            if (utilityToken.issuanceType == 0) // mint
                IERC1155(utilityToken.addr).mint(user_, utilityToken.tokenId, amount);
            else
                IERC1155(utilityToken.addr).safeTransferFrom(address(this), user_, utilityToken.tokenId, amount, "");
        }
    }

    function transferReward(address from_, address to_, uint256 tokenIndex_) external {

        UtilityToken memory utilityToken = utilityTokens[tokenIndex_];

        if (msg.sender != address(utilityToken.manager)) revert NotManagingContract();

        uint256 time = _getTime(utilityToken.start, utilityToken.end);

        if (time > 0) {
            _updateUserData(from_, tokenIndex_, time);
            _updateUserData(to_, tokenIndex_, time);
        }
    }

    function burn(address from_, uint256 amount_, uint256 tokenIndex_) external {

        UtilityToken memory utilityToken = utilityTokens[tokenIndex_];

        if (msg.sender != address(utilityToken.manager)) revert NotManagingContract();

        uint256 tokenType = uint256(utilityToken.tokenType);

        if (tokenType == 20) {
            IERC20(utilityToken.addr).burnFrom(from_, amount_);
        }
        else if (tokenType == 1155) {
            IERC1155(utilityToken.addr).burnFrom(from_, amount_);
        }
    }

   function _getTime(uint256 tokenStart_, uint256 tokenEnd_) internal view  returns (uint256 time) {
         uint256 _n = block.timestamp;
         if (_n > tokenStart_) {
            time = _min(_n, tokenEnd_);
         }
    }

    function _updateUserData(address user_, uint256 tokenIndex_, uint256 time_)  internal {
        if (user_ == address(0)) return;
        uint256 rewards;
        bool claimable;
        UserData storage ud = userData[user_][tokenIndex_];
        (rewards, claimable) = getTotalClaimable(user_, tokenIndex_);
        if (claimable) {
            ud.rewards = rewards;
        }
        if (ud.lastUpdate < time_) {
            ud.lastUpdate = time_;
        }
    }

    /**
     * Helpers
     */

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}