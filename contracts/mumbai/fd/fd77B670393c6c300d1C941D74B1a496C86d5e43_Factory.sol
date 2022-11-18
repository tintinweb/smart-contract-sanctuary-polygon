// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {
    uint256 public contract_activated_time;
    uint256 public time_to_raise_dispute;
    address public passenger;
    address public driver;
    address public arbitrator;
    uint256 public amount_payable;
    uint256 public arbitration_fee;
    bool public activated_by_driver = false;
    bool public activated_by_passenger = false;
    bool public contract_activated = false;
    bool public dispute_raised = false;
    bool public contract_settled = false;
    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE
    }

    State public currState;

    modifier onlyDriver() {
        require(msg.sender == driver, "Only driver can call this method");
        _;
    }

    constructor(
        address _arbitrator,
        address _passenger,
        uint256 _amount_payable,
        uint256 _arbitration_fee
    ) {
        arbitrator = _arbitrator;
        passenger = _passenger;
        amount_payable = _amount_payable;
        arbitration_fee = _arbitration_fee;
    }

    //pay to contract by passenger
    function payment_by_passenger() public payable {
        //check if amount paid is not less than amount payable
        require(
            msg.value >= (amount_payable + arbitration_fee) &&
                !contract_activated &&
                msg.sender == passenger,
            "Only passenger can handle this method or has insufficient funds"
        );
        uint256 amount_paid = msg.value;
        uint256 amount_payable_by_passenger = amount_payable + arbitration_fee;

        //if paid extra, return that amount
        if (amount_payable_by_passenger != amount_paid) {
            uint256 amount_to_return = amount_paid -
                amount_payable_by_passenger;
            payable(msg.sender).transfer(amount_to_return);
        }
        activated_by_passenger = true;
    }

    //called by driver if start the travel
    function startRide_by_driver(address _driver) external payable {
        driver = _driver;
        require(
            currState == State.AWAITING_PAYMENT && activated_by_passenger,
            "Already paid"
        );
        currState = State.AWAITING_DELIVERY;
        contract_activated = true;
        activated_by_driver = true;
        contract_activated_time = block.timestamp; //block.timestamp
    }

    //called by passenger if transaction occured successfully
    function confirmDelivery() public {
        require(
            msg.sender == passenger && currState == State.AWAITING_DELIVERY,
            "Only passenger can handle this method or Cannot confirm delivery"
        );
        currState = State.COMPLETE;
        payable(arbitrator).transfer(arbitration_fee);
        uint256 amount_payable_to_driver = amount_payable;
        payable(driver).transfer(amount_payable_to_driver);
        contract_settled = true;
    }

    //called by anyone(generally driver if time_to_raise_dispute is passed
    function force_settle() public {
        require(
            block.timestamp > (time_to_raise_dispute + contract_activated_time)
        );
        payable(passenger).transfer(arbitration_fee);
        uint256 amount_payable_to_driver = arbitration_fee + amount_payable;
        payable(driver).transfer(amount_payable_to_driver);
        contract_settled = true;
    }

    //withdraw money if other party is taking too much time or any other reason
    function withdraw_by_passenger() public {
        require(
            activated_by_passenger &&
                contract_activated == false &&
                msg.sender == passenger
        );
        activated_by_passenger = true;
        uint256 amount_payable_by_passenger = amount_payable + arbitration_fee;
        payable(passenger).transfer(amount_payable_by_passenger);
    }

    //withdraw money if other party is taking too much time or any other reason
    function withdraw_by_driver() public {
        require(
            activated_by_driver &&
                contract_activated == false &&
                msg.sender == passenger
        );

        payable(passenger).transfer(arbitration_fee);
    }

    //Faltaria sumar dos funciones mas: (B2: confirmDriver y variable C: Api de coordenadas)

    // function raise_dispute() public {
    //     require(msg.sender == passenger);
    //     dispute_raised = true;
    // }

    function pay_to_driver() public {
        require(msg.sender == arbitrator && dispute_raised == true);
        payable(arbitrator).transfer(arbitration_fee);
        uint256 amount_payable_to_driver = arbitration_fee + amount_payable;
        payable(driver).transfer(amount_payable_to_driver);
        contract_settled = true;
    }
}

contract Factory {
    Escrow[] public deployedContracts;
    address public lastContractAddress;
    event ContractCreated(address newAddress);

    function createNew(
        address _passenger,
        uint256 _amount_payable,
        uint256 _arbitration_fee
    ) public returns (address contractAddress) {
        require(
            _amount_payable > 0 && _arbitration_fee > 0,
            "Amount payable and arbitration fee should be greater than 0"
        );
        Escrow t = new Escrow(
            msg.sender,
            _passenger,
            _amount_payable,
            _arbitration_fee
        );
        contractAddress = address(t);
        deployedContracts.push(t);
        lastContractAddress = contractAddress;
        return contractAddress;
    }
}