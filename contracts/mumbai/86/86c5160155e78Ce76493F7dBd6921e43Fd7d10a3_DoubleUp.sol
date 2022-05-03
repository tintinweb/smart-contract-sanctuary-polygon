// contracts/DoubleUp.sol
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "../external/openzeppelin/contracts/access/Ownable.sol";
import "../external/openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DoubleUp is Ownable, ReentrancyGuard {
    struct Entry {
        address next;
        uint256 collateral;
        uint256 immunity;
        string message;
    }

    mapping(address => Entry) public entries;
    uint256 public entriesLength;

    address public head;
    address public tail;

    uint256 public constant minimumEntry = 1;
    uint256 public constant maximumEntry = 10;
    //uint256 public constant entryToCost = 100 * 10**uint(18); //1 => 100 Matic, 10=> 1000 Matic for fees
    uint256 public constant entryToCost = 1 * 10**uint(13);

    uint256 public constant immunityCostDivisor = 25; //amount / immunityCostDivisor = cost per immunity.

    uint256 public constant immunityMax = 5;

    uint256 public constant take = 50; //amount / take == contract cut and bonus cut

    uint256 public constant winnersUntilTriple = 5;

    uint256 public devFunds = 0; //accumulates through playing
    uint256 public bonusPrize = 0;

    uint256 public constant eliminationsUntilBonus = 25;
    uint256 public eliminationCounter = 0;

    uint256 public prizesPaidTotal = 0;

    uint256 public winnerCounter = 0;

    bool public refundsActive = false;

    //emits tokens purchased minus the decimal places. (IE: 1 token is not emitted as 1^18)
    //we only deal with full token purchases within this contract.
    event Prize(address indexed prizeAddress, uint earnings, uint updatedWinnerCounter, bool earnedBonus);
    event Eliminated(address indexed eliminatedAddress, uint collateral);
    event Damaged(address indexed target, uint newImmunityLevel);
    event Entered(address indexed newPlayer, uint collateral, uint immunityLevel, string message);
    event BalanceUpdate(uint balance, uint bonus, uint currentWinTarget);
    event MessageUpdate(address indexed target, string message);

    constructor(){
        entries[msg.sender] = Entry(address(0), (maximumEntry * entryToCost), 0, "Crypto Dungeon Team Starting Entry! Best of luck one and all! <3 Keep an eye open for our upcoming token launch: Blood Souls (SOULS).");
        entriesLength = 1;
        head = msg.sender;
        tail = msg.sender;
    }

    function accumulatedBalance() view public returns(uint256) {
        return address(this).balance - devFunds;
    }

    function entryState() view external returns(address[] memory addresses, uint[] memory immunities, uint[] memory amounts, string[] memory messages, uint256 balance){
        addresses = new address[](entriesLength);
        immunities = new uint[](entriesLength);
        amounts = new uint[](entriesLength);
        messages = new string[](entriesLength);

        if(entriesLength == 0){
            return (addresses, immunities, amounts, messages, accumulatedBalance());
        }

        address currentAddress = head;
        Entry storage current = entries[head];
        for(uint count = 0;count < entriesLength;++count){
            immunities[count] = current.immunity;
            amounts[count] = current.collateral;
            addresses[count] = currentAddress;
            messages[count] = current.message;
            if(current.next == address(0)){
                break;
            }

            currentAddress = current.next;
            current = entries[current.next];
        }
        return (addresses, immunities, amounts, messages, accumulatedBalance());
    }

    function updateMessage(string calldata message) external {
        require(bytes(message).length <= 256, "Message length exceeded");
        entries[msg.sender].message = message;
        emit MessageUpdate(msg.sender, message);
    }

    function enter(uint256 entry, uint256 immunityLevel, string calldata message) payable external nonReentrant {
        enterImplementation(entry, immunityLevel, message, msg.sender);
    }

    //Allows for testing with randomly generated addresses. This is really only useful in dev testing scenarios
    //without needing to actually generate a ton of wallets, we can just pass in made up addresses since we don't
    //care in a testing scenario about actually getting the winning prize sent to a real person's address.
    //This method is not beneficial outside of testing and so is safe to leave in the final contract since it cannot be exploited.
    function enterWithAddress(uint256 entry, uint256 immunityLevel, string calldata message, address msgSender) payable external onlyOwner nonReentrant {
        enterImplementation(entry, immunityLevel, message, msgSender);
    }

    function enterImplementation(uint256 entry, uint256 immunityLevel, string calldata message, address msgSender) private {
        require(refundsActive == false, "Contract retired.");
        require(entry >= minimumEntry && entry <= maximumEntry, "Out of range entry.");
        require(immunityLevel <= immunityMax, "Immunity too high.");
        require(entries[msgSender].collateral == 0, "Already in line!");
        require(bytes(message).length <= 256, "Message length exceeded");

        uint256 collateral = entry * entryToCost;
        require(msg.value == collateral, "Wrong entry fee!");

        uint256 immunityCost = (collateral / immunityCostDivisor) * immunityLevel;
        uint256 devTakeAndBonusTake = collateral / take;

        collateral -= immunityCost; //immunityCost subtracts from collateral thus reducing winnings.

        //We want to split the immunity cost with the bonus pool but not have any rounding issues, so split the variable this way.
        uint256 halfImmunity = immunityCost / 2;
        immunityCost -= halfImmunity;

        bonusPrize += (devTakeAndBonusTake + halfImmunity);
        devFunds += (devTakeAndBonusTake + immunityCost);

        Entry storage current = entries[head];

        uint256 winMultiple = (winnerCounter % winnersUntilTriple) == 0 ? 3 : 2;
        uint256 currentWinTarget = current.collateral * winMultiple;
        uint256 currentActionableBalance = address(this).balance - devFunds - bonusPrize;
        for(uint max = 0;max < 6 && head != address(0) && (currentWinTarget >= currentActionableBalance);++max){
            uint256 amountWon = currentWinTarget;
            uint256 totalAmountWon = amountWon;
            if(eliminationCounter >= eliminationsUntilBonus){
                totalAmountWon+=bonusPrize;
                eliminationCounter = 0;
                bonusPrize = 0;
                emit Prize(head, amountWon + bonusPrize, winnerCounter + 1, true);
            }else{
                emit Prize(head, amountWon, winnerCounter + 1, false);
            }
            prizesPaidTotal+=totalAmountWon;
            payable(head).transfer(totalAmountWon);
            //this line intentionally increments the winnerCounter
            winMultiple = (++winnerCounter % winnersUntilTriple) == 0 ? 3 : 2;

            currentActionableBalance-=amountWon; //don't include the bonus when subracting.

            current.collateral = 0;
            head = current.next;
            if(head != address(0)){
                currentWinTarget = current.collateral * winMultiple;
            }
            entriesLength--;
        }
        
        if(entriesLength >= 4){
            address currentAddress = head;
            current = entries[currentAddress];
            Entry storage next = entries[current.next];
            //751 == (maxImmunity(5) * 2) + (maxEntries(10) / 2) == 15 * spots(50) + 1
            //This is to give an upper bound on the max amount of iterations we can expect here.
            for(uint max = 0;max < 751 && next.immunity != 0;++max){
                emit Damaged(current.next, --next.immunity);
                if(next.next == address(0)){
                    currentAddress = head;
                    current = entries[currentAddress];
                    next = entries[current.next];
                }else{
                    currentAddress = current.next;
                    current = next;
                    next = entries[next.next];
                }
            }
            eliminationCounter++;
            emit Eliminated(current.next, next.collateral);
            next.collateral = 0; //no longer in the lineup
            if(next.next == address(0)){
                current.next = msgSender;
            }else{
                current.next = next.next; // Clip
                entries[tail].next = msgSender;
            }
        }else{
            entriesLength++;
            if(head == address(0)){
                head = msgSender;
            }else{
                entries[tail].next = msgSender;
            }
        }

        tail = msgSender;
        uint immunityLevelFinal = immunityLevel > 0 ? (immunityLevel * 2) + (entry / 2) : 0;
        entries[msgSender] = Entry(address(0), collateral, immunityLevelFinal, message);
        emit Entered(msgSender, collateral, immunityLevelFinal, message);
        emit BalanceUpdate(currentActionableBalance, bonusPrize, currentWinTarget);
    }

    function withdrawDevFundBalance() external onlyOwner {
        payable(msg.sender).transfer(devFunds);
        devFunds = 0;
    }

    //useful if there's some bug with the contract and we need to migrate. Players will need to manually claim still.
    function refundPlayersAndTerminate() external onlyOwner {
        refundsActive = true;
    }

    function getRefund() external {
        require(refundsActive == true, "Refunds not enabled.");

        uint collateral = entries[msg.sender].collateral;
        require(collateral != 0, "Nothing to withdraw.");
        payable(msg.sender).transfer(entries[msg.sender].collateral);
        entries[msg.sender].collateral = 0;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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