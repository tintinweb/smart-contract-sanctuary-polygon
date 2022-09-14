/**
 *Submitted for verification at polygonscan.com on 2022-09-14
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/Prode.sol


pragma solidity 0.8.9;


contract Prode is ReentrancyGuard {
    //List of users
    address[] private users;

    struct User {
        bool enter;
        bool winner;
        uint amount;
    }

    mapping(address => User) public mapUser;   
    address payable public owner;
    address payable public governance;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address payable _governance) {
        owner = payable(msg.sender);
        governance = payable(_governance);
    }

    event Withdraw(address indexed adr, uint amount);
    event Deposit(address indexed adr);

    /**
     @notice GetTotalUsers
     Know how many participants are in the game
    */
    function getTotalUsers() public view returns (uint) {
        return users.length;
    }

    function deposit() public payable {
        require(msg.value >= 25 ether, "To enter the minimum is 25");
        users.push(payable(msg.sender));
        mapUser[msg.sender].enter = true;
        transfer(owner, 2.5 ether);
        transfer(governance, 2.5 ether);
        emit Deposit(msg.sender);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function userHasEnter(address user) public view returns (bool) {
        return mapUser[user].enter;
    }


    function transfer(address payable _to, uint _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function pickWinner(address winner, uint amount) public onlyOwner {
        require(amount > 0,"Amount have to be greater than 0");
        require(mapUser[msg.sender].enter, "User has to be a participant");
        require(address(this).balance >= amount, "Balance is not enough");
        mapUser[winner].amount = amount;
        mapUser[winner].winner = true;
    }

    /**
     @notice Withdraw
     Winner can withdraw his funds.
     */
    function withdraw() public nonReentrant {
        require(mapUser[msg.sender].winner, "User is not winner");
        require(
            mapUser[msg.sender].amount > 0,
            "Balance have to be more than 0"
        );
        uint _amount = mapUser[msg.sender].amount;
        mapUser[msg.sender].amount = 0;
        transfer(payable(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }
}