/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: MIT

// File: contracts/CarefulMath.sol



pragma solidity ^0.8.0;

/**
  * @title Careful Math
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}
// File: contracts/ERC20NonStandardInterface.sol



pragma solidity ^0.8.0;

/**
 * @title ERC20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface ERC20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
// File: contracts/DePayGateway.sol



pragma solidity ^0.8.0;



contract DePayGateway is CarefulMath {

    uint256 internal PAYMENT_EXPIRY_PERIOD = 7 days;

    address payable public admin;
    address payable public pendingAdmin;

    struct EscrowPayment {
        uint256 senderId;
        address payable senderAddress;
        uint256 destinationId;
        uint256 amount;
        uint256 expiryTime;
    }

    event EthTransfered(
        address indexed senderAddress,
        address indexed destinationAddress,
        uint256 amount
    );

    event EthAddedToEscrow(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        uint256 amount,
        uint256 expiresOn
    );

    event ClaimEthTransfered(
        uint256 indexed itemId,
        uint256 indexed senderId,
        address indexed destinationAddress,
        uint256 amount
    );

    event RefundEthTransfered(
        uint256 indexed itemId,
        address indexed senderAddress,
        uint256 indexed destinationId,
        uint256 amount
    );

     event Erc20TokenTransfered(
        address indexed senderAddress,
        address indexed destinationAddress,
        address tokenAddress,
        uint256 amount
    );

    event Erc20TokenAddedToEscrow(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        address tokenAddress,
        uint256 amount,
        uint256 expiresOn
    );

    event ClaimErc20TokenTransfered(
        uint256 indexed itemId,
        uint256 indexed senderId,
        address indexed destinationAddress,
        address tokenAddress,
        uint256 amount
    );
    event RefundErc20TokenTransfered(
        uint256 indexed itemId,
        address indexed senderAddress,
        uint256 indexed destinationId,
        address tokenAddress,
        uint256 amount
    );

    /**
     * @dev mapping escrow payments for ETH and ERC20 tokens
     */
    mapping(uint256 => EscrowPayment) public escrowEthPayments;

    mapping(uint256 => mapping(address => EscrowPayment)) public escrowErc20Payments;

    constructor() {
        admin = payable(msg.sender);
    }

    /**
     * @notice Send ether from sender account to destination account
     * @param destinationAddress The destination account
     */
    function sendEthAmountToWallet(address payable destinationAddress) public payable {
        require(msg.value > 0);
        require(msg.sender != destinationAddress);

        destinationAddress.transfer(msg.value);
        emit EthTransfered(msg.sender, destinationAddress, msg.value);
    }

    /**
     * @notice Send ether from sender account to escorw account
     * @param senderId The sender unique ID generated by DPN
     * @param destinationId The destination unique ID generated by DPN
     */

    function sendEthAmountToEscorw(uint256 senderId, uint256 destinationId) public payable {
        require(senderId != 0 && senderId != destinationId);

        MathError error;
        uint256 expiryTime;
        (error, expiryTime) = addUInt(PAYMENT_EXPIRY_PERIOD, block.timestamp);

        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowEthPayments[mappingId];

        if (payment.destinationId == destinationId) {
            (error, payment.amount) = addUInt(payment.amount, msg.value);
            payment.expiryTime = expiryTime;
        } else {
            escrowEthPayments[mappingId] = EscrowPayment({
                senderId: senderId,
                senderAddress: payable(msg.sender),
                destinationId: destinationId,
                amount: msg.value,
                expiryTime: expiryTime
            });
        }

        emit EthAddedToEscrow(
            mappingId,
            senderId,
            destinationId,
            msg.value,
            expiryTime
        );
    }

    /**
     * @notice Destination account claim the amount from the escorw
     * @param senderId The sender unique ID generated by DPN
     * @param destinationId The destination unique ID generated by DPN
     * @param destinationAddress The destination address of the user
     */
    function claimEthAmount(uint256 senderId, uint256 destinationId, address payable destinationAddress) public onlyAdmin {
        require(destinationId != 0 && senderId != destinationId);
        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowEthPayments[mappingId];
        require(
            payment.destinationId == destinationId && payment.amount > 0 && payment.expiryTime > block.timestamp
        );

        uint256 claimAmount = payment.amount;
        payment.amount = 0;

        destinationAddress.transfer(claimAmount);

        emit ClaimEthTransfered(
            mappingId,
            senderId,
            destinationAddress,
            claimAmount
        );
    }

    /**
     * @notice Sender account claim the amount from the escorw when the payment expires
     * @param senderId The sender unique ID generated by DPN
     * @param destinationId The destination unique ID generated by DPN
     */
    function refundEthAmount(uint256 senderId, uint256 destinationId) public {
        require(senderId != 0 && senderId != destinationId);
        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowEthPayments[mappingId];
        require(
            payment.senderAddress == msg.sender &&
                payment.amount > 0 &&
                payment.expiryTime < block.timestamp
        );

        address payable senderAddress = payment.senderAddress;

        uint256 refundAmount = payment.amount;
        payment.amount = 0;

        senderAddress.transfer(refundAmount);

        emit RefundEthTransfered(
            mappingId,
            senderAddress,
            destinationId,
            refundAmount
        );
    }

    /**
     * @notice Send ERC20 token from sender account to destination account
     * @param destinationAddress The destination account
     */
    function sendErc20TokenToWallet(address payable destinationAddress, address token, uint256 amount) public {
        require(msg.sender != destinationAddress);
        require(amount > 0 && token != address(0x0));

        doTransferIn(token, msg.sender, destinationAddress, amount);
        emit Erc20TokenTransfered(msg.sender, destinationAddress, token, amount);
    }

    /**
     * @notice Send ERC20 token from sender account to escorw account
     * @param senderId The sender unique ID generated by DPN
     * @param destinationId The destination unique ID generated by DPN
     * @param token The ERC20 token address
     * @param amount The token value to be sent from the sender account
     */
    function sendErc20TokenToEscorw(uint256 senderId, uint256 destinationId, address token, uint256 amount) public {
        require(senderId != 0 && senderId != destinationId && token != address(0x0));

        
        MathError error;
        uint256 expiryTime;
        (error, expiryTime) = addUInt(
            PAYMENT_EXPIRY_PERIOD,
            block.timestamp
        );

        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowErc20Payments[mappingId][address(token)];

        if (payment.destinationId == destinationId) {
            (error, payment.amount) = addUInt(payment.amount, amount);
            payment.expiryTime = expiryTime;
        } else {
            escrowErc20Payments[mappingId][address(token)] = EscrowPayment({
                senderId: senderId,
                senderAddress: payable(msg.sender),
                destinationId: destinationId,
                amount: amount,
                expiryTime: expiryTime
            });
        }

        uint256 escrowAmount =
            doTransferIn(
                token,
                msg.sender,
                payable(address(this)),
                amount
            );

        emit Erc20TokenAddedToEscrow(
            mappingId,
            senderId,
            destinationId,
            token,
            escrowAmount,
            expiryTime
        );
    }

    /**
     * @notice Destination account claim the amount from the escorw
     * @param senderId The sender unique ID generated by DPN
     * @param destinationId The destination unique ID generated by DPN
     * @param destinationAddress The destination address of the user
     * @param token The ERC20 token address
     */

    function claimErc20Token(uint256 senderId, uint256 destinationId, address payable destinationAddress, address token) public onlyAdmin {
        require(destinationId != 0 && senderId != destinationId && token != address(0x0));

        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowErc20Payments[mappingId][address(token)];
        require(
            payment.amount > 0 && payment.expiryTime > block.timestamp
        );

        uint256 claimAmount = payment.amount;
        payment.amount = 0;

        doTransferOut(token, destinationAddress, claimAmount);

        emit ClaimErc20TokenTransfered(
            mappingId,
            senderId,
            destinationAddress,
            token,
            claimAmount
        );
    }

    /**
     * @notice Sender account claim the amount from the escorw when the payment expires
     * @param senderId The sender unique ID generated by DPN
     * @param destinationId The destination unique ID generated by DPN
     * @param token The ERC20 token address
     */

    function refundErc20Token(uint256 senderId, uint256 destinationId, address token) public {
        require(
            senderId != 0 && senderId != destinationId && token != address(0x0)
        );
        
        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowErc20Payments[mappingId][address(token)];
        require(
                payment.senderAddress == msg.sender &&
                payment.amount > 0 &&
                payment.expiryTime < block.timestamp
        );

        address payable senderAddress = payment.senderAddress;

        uint256 refundAmount = payment.amount;
        payment.amount = 0;

        doTransferOut(token, senderAddress, refundAmount);

        emit RefundErc20TokenTransfered(
            mappingId,
            senderAddress,
            destinationId,
            token,
            refundAmount
        );
    }

    /**
     * @notice Sets new payment expiry period in days
     * @param paymentExpiryPeriod The expiry period in days
     */
    function setPaymentExpiryPeriod(uint256 paymentExpiryPeriod) public {
        // Check caller = admin
        require(msg.sender == admin);
        PAYMENT_EXPIRY_PERIOD = paymentExpiryPeriod;
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address payable newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin);

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin);
        require(msg.sender != address(0));

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = payable(address(0));
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /**
     * @dev Similar to ERC20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     */
    function doTransferIn(address tokenAddress, address from, address payable to, uint256 amount) internal returns (uint256) {
        ERC20NonStandardInterface token = ERC20NonStandardInterface(tokenAddress);
        uint256 balanceBefore = ERC20NonStandardInterface(token).balanceOf(address(this));
        token.transferFrom(from, to, amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = ERC20NonStandardInterface(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to ERC20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address tokenAddress, address payable to, uint256 amount) internal returns (uint256) {
        ERC20NonStandardInterface token = ERC20NonStandardInterface(address(tokenAddress));
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");

        return 0;
    }

    /**
     * @notice Generate a unique Id from the sender and destination numbers
     * @param fromNumber The sender Id
     * @param toNumber The destination Id
     * @return The unique Id
     */
    function getUniqueId(uint256 fromNumber, uint256 toNumber) internal pure returns (uint256) {
        string memory label = append(uintToStr(fromNumber), "", uintToStr(toNumber));
        bytes32 hash = keccak256(bytes(label));
        return uint256(hash);
    }

    /**
     * @notice Convert from given uint to string
     * @param _i The integer value
     * @return _uintAsString The string value
     */
    function uintToStr(uint256 _i) internal pure returns (string memory _uintAsString) {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }
        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number != 0) {
            bstr[k--] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        return string(bstr);
    }

    /**
     * @notice Concatenate the given string values
     * @param a The first string value
     * @param b The second string value
     * @param c The third string value
     * @return The string value
     */
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    /**
     * @notice Get the hashId of the `value`
     * @param value The value to be hashed
     * @return The hashId
     */
    function getId(uint256 value) public pure returns (uint256) {
        // return phoneNumberMapping[phoneNumber];
        bytes32 label = keccak256(toBytes(value));
        return uint256(label);
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
}