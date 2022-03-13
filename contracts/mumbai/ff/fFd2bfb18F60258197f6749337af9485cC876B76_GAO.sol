// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IBall.sol";
import "../interfaces/IBallStruct.sol";

contract GAO is Context, Ownable {
    IBall public ballContract;

    string public ballTokenURIPrefix;

    uint256 public singleItemPrice;
    uint256 public packItemPrice;

    struct BallItem {
        uint8 percentage;
        uint24 salesCountLimit; // 0 = unlimited
        bool isPackGuaranteed;
        Ball data;
    }

    BallItem[] public ballItems;

    bool public isOpen;

    uint256 private _randomBallNonce;

    mapping(uint256 => uint256) public ballItemSalesCountByBallItemIndex;
    mapping(uint256 => uint256) public currentEditionSaleBySet;

    event SingleItemBought(address _buyer, uint256 _price);
    event PackItemBought(address _buyer, uint256 _price);

    constructor(
        address _ballContractAddress,
        string memory _tokenURIPrefix,
        uint256 _singleItemPrice,
        uint256 _packItemPrice,
        BallItem[] memory _ballItems,
        bool _isOpen
    ) {
        setBallContract(_ballContractAddress);
        setBallTokenURIPrefix(_tokenURIPrefix);
        setSingleItemPrice(_singleItemPrice);
        setPackItemPrice(_packItemPrice);
        setBallItems(_ballItems);
        setIsOpen(_isOpen);
    }

    // Simplified EIP-165 for wrapper contracts to detect if they are targeting the right contract
    function isGAO() external pure returns (bool) {
        return true;
    }

    /* External contracts management */
    function setBallContract(address _address) public onlyOwner {
        IBall candidateContract = IBall(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.isBall(),
            "CONTRACT_ADDRES_IS_NOT_A_BALL_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        ballContract = candidateContract;
    }

    /* Parameters management */
    function setBallTokenURIPrefix(string memory _prefix) public onlyOwner {
        ballTokenURIPrefix = _prefix;
    }

    function setSingleItemPrice(uint256 _singleItemPrice) public onlyOwner {
        singleItemPrice = _singleItemPrice;
    }

    function setPackItemPrice(uint256 _packItemPrice) public onlyOwner {
        packItemPrice = _packItemPrice;
    }

    function setBallItems(BallItem[] memory _ballItems) public onlyOwner {
        for (uint256 i = 0; i < _ballItems.length; i++) {
            ballItems.push(_ballItems[i]);
        }
    }

    function setIsOpen(bool _isOpen) public onlyOwner {
        isOpen = _isOpen;
    }

    /* Helpers */
    function _getEditionSize(uint8 _edition) private pure returns (uint256) {
        return _edition * 100;
    }

    function _matchIsBallItemIndexSoldOut(uint256 _ballItemIndex)
        private
        view
        returns (bool)
    {
        return
            ballItems[_ballItemIndex].salesCountLimit > 0 &&
            ballItemSalesCountByBallItemIndex[_ballItemIndex] <
            ballItems[_ballItemIndex].salesCountLimit;
    }

    function _getRandomBallItemIndex() private returns (uint256) {
        // Get the cumulative percentage of all non sold out balls
        uint16 cumulativePercentage = 0;
        for (uint256 i = 0; i < ballItems.length; i++) {
            if (_matchIsBallItemIndexSoldOut(i)) {
                continue;
            }

            cumulativePercentage += ballItems[i].percentage;
        }

        // Generate a random number between 0 and the cumulative percentage
        _randomBallNonce++;
        uint256 randomPercentage = _getRandomPercentage(cumulativePercentage);

        // Check balls one by one until we find a match by percentage range
        uint16 accumulatedPercentage = 0;
        for (uint256 i = 0; i < ballItems.length - 1; i++) {
            if (_matchIsBallItemIndexSoldOut(i)) {
                continue;
            }

            accumulatedPercentage += ballItems[i].percentage;

            if (randomPercentage <= accumulatedPercentage) {
                return i;
            }
        }

        // If there has been no percentage match yet it means the last ball item was chosen
        return ballItems.length - 1;
    }

    function _mintBall(Ball memory _data) private {
        ballContract.mint(_msgSender(), ballTokenURIPrefix, _data);

        // Manage edition sales count
        if (
            currentEditionSaleBySet[_data.set] + 1 ==
            _getEditionSize(_data.edition)
        ) {
            currentEditionSaleBySet[_data.set] = 0;
            _data.edition = _data.edition + 1;
        } else {
            currentEditionSaleBySet[_data.set] += 1;
        }
    }

    /* Sale items */
    function buySingle() external payable {
        require(isOpen, "SALE_IS_NOT_OPEN");

        require(msg.value == singleItemPrice, "VALUE_INCORRECT");

        uint256 randomBallItemIndex = _getRandomBallItemIndex();

        _mintBall(ballItems[randomBallItemIndex].data);

        ballItemSalesCountByBallItemIndex[randomBallItemIndex] += 1;

        emit SingleItemBought(_msgSender(), singleItemPrice);
    }

    function buyPack() external payable {
        require(isOpen, "SALE_IS_NOT_OPEN");

        require(msg.value == packItemPrice, "VALUE_INCORRECT");

        // First 4 balls are random
        for (uint256 i = 0; i < 4; i++) {
            uint256 randomBallItemIndex = _getRandomBallItemIndex();

            _mintBall(ballItems[randomBallItemIndex].data);

            ballItemSalesCountByBallItemIndex[randomBallItemIndex] += 1;
        }

        // Last one is the special one we guarantee
        for (uint256 i = 0; i < ballItems.length; i++) {
            if (ballItems[i].isPackGuaranteed) {
                _mintBall(ballItems[i].data);

                ballItemSalesCountByBallItemIndex[i] += 1;
            }
        }

        emit PackItemBought(_msgSender(), packItemPrice);
    }

    /* Funds management */
    function withdraw(address _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "WITHDRAW_FAILED");
    }

    function recoverERC20(
        address _tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(
            IERC20(_tokenAddress).transfer(_to, _tokenAmount),
            "RECOVERY_FAILED"
        );
    }

    /* Utils */
    function _getRandomPercentage(uint256 _maxPercentage)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        _msgSender(),
                        _randomBallNonce
                    )
                )
            ) % (_maxPercentage + 1); // +1 allows you to have a inclusive range [0, N]
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IBallStruct.sol";

interface IBall {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function getBall(uint256 _tokenId) external view returns (Ball memory);

    function getApproved(uint256 _tokenId) external view returns (address);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ball calldata _ballData
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function isBall() external pure returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Ball {
    uint16 serverId;
    uint16 set;
    uint8 edition;
    uint16 minRunes;
    uint16 maxRunes;
    bool isShinny;
    string name;
}