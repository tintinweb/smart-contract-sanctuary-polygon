/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/coinflip.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
contract Coinflip is Ownable,ReentrancyGuard {
    uint256 private probs;
    uint256 private randNumber = 5.66 ether;
    bytes32 private randSeed;
    uint256 private lowerProbs;
    uint256 private higherProbs;
    uint256 private maxMultipleLimit = 2;
    uint256 private initTimestamp;
    uint256 private lastBlockNumber;
    uint256 private lastTimeStamp;
    uint256 public minWager;
    uint256 public maxWager;
    uint256 public multiple = 2;
    address public trusted;
    uint256 public feePercent = 25;
    mapping(address => uint256) public claims;

    event result(
        address indexed player,
        uint256 result,
        uint256 prizeValue,
        uint256 bet,
        uint256 wager
    );

    event funding(address indexed sender,uint256 amount);

    constructor(
        bytes32 _randomSeed,
        uint256 _minimumWager,
        uint256 _maxWager,
        uint256 _lowerProbs,
        uint256 _higherProbs
        
    ) {
        randSeed = _randomSeed;
        lowerProbs = _lowerProbs;
        higherProbs = _higherProbs;
        minWager = _minimumWager;
        maxWager = _maxWager;
        initTimestamp = block.timestamp;
        lastBlockNumber = block.number;
        
    }

    receive() external payable onlyOwner {
        emit funding(msg.sender,msg.value);
    }

    function flipCoin(uint256 bet) external payable nonReentrant {
        require(bet == 1 || bet == 0, "invalid bet value");
        require(msg.value > 0, "Cannot make bet of 0 Matic");
        require(
            msg.value >= minWager,
            "The Wager Value Is Less Than Minimum Allowed"
        );
        require(
            msg.value <= maxWager,
            "The Wager Value Is More Than Maximum Allowed"
        );

        uint256 originalBet = ((msg.value * 1000) / (1000 + feePercent));

        uint256 fees = msg.value - originalBet;

        changeRand();

        uint256 valToSend = 0;
        uint256 sampRange = randNumber % 1000;
        uint256 currResult = 0;
        address caller = msg.sender;

        if (bet == 0) {
            if (sampRange < lowerProbs) {
                valToSend = originalBet * 2;
                currResult = 1;
            }
        } else {
            if (sampRange > higherProbs) {
                valToSend = originalBet * 2;
                currResult = 1;
            }
        }
        if (address(this).balance < valToSend + fees) {
            revert('Insufficient Matic Balance');
        }

        emit result(caller, currResult, valToSend, bet, originalBet);
    
        lastBlockNumber = block.number;
        lastTimeStamp = block.timestamp;
        sendPayment(owner(), fees);

        sendPayment(msg.sender, valToSend);
    }

    

    function changeRand() internal {
        require(block.timestamp > initTimestamp);
        require(block.number > lastBlockNumber);
        randSeed = bytes32(abi.encodePacked(randNumber,block.number));
        uint256 newRand = (
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        randNumber,
                        randSeed,
                        block.number,
                        block.difficulty,
                        block.timestamp
                    )
                )
            )
        ) % 0.985219 ether;
        randNumber = newRand;
    }

    function _changeMultiples(uint256 _newMultiple) internal {
        multiple = _newMultiple;
    }

    function sendPayment(address receiver, uint256 valToSend) internal {
        (bool sent, bytes memory data) = receiver.call{value: valToSend}("");
        require(sent);

    }

    function setFeePercent(uint256 newPercent) external onlyOwner nonReentrant {
        feePercent = newPercent;
    }

    function changeProbs(uint256 _lowerProbs,uint256 _higherProbs) external onlyOwner nonReentrant {
        lowerProbs = _lowerProbs;
        higherProbs = _higherProbs;
    }

    function changeWagers(uint256 _newMin, uint256 _newMax) external onlyOwner nonReentrant {
        minWager = _newMin;
        maxWager = _newMax;
    }

    function changeMultiples(uint256 _newMultiple) external onlyOwner nonReentrant {
        _changeMultiples(_newMultiple);
    }

    function changeRandSeed(bytes32 newSeed) external onlyOwner nonReentrant {
        randSeed = newSeed;
    }

    function changeMaxMultiples(uint256 _newMax) external onlyOwner nonReentrant {
        maxMultipleLimit = _newMax;
    }

    function withdraw() external onlyOwner nonReentrant {
        sendPayment(msg.sender, address(this).balance);
        
    }

}