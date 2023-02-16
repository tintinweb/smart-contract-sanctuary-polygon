import "./TransferHelper.sol";
import "./SafeMath.sol";

contract BTCLNtoEVM {

    using SafeMath for uint256;

    struct AtomicSwapStruct {
        address intermediary;
        address token;
        uint256 amount;
        bytes32 paymentHash;
        uint64 expiry;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    mapping(bytes32 => bytes32) commitments;
    mapping(address => mapping(address => uint256)) balances;

    event PaymentRequest(address indexed offerer, address indexed claimer, bytes32 indexed paymentHash, AtomicSwapStruct data);
    event Claimed(address indexed offerer, address indexed claimer, bytes32 indexed paymentHash, bytes32 secret);
    event Refunded(address indexed offerer, address indexed claimer, bytes32 indexed paymentHash);

    function getHash(AtomicSwapStruct calldata data, uint64 timeout, Signature calldata sig, bytes memory kind) public pure returns (bytes32) {
        bytes32 hashedMessage = keccak256(abi.encode(kind,data,timeout));
        return hashedMessage;
    }

    function getAddress(bytes32 commitment, uint64 timeout, Signature calldata sig, bytes memory kind) private pure returns (address) {
        bytes32 hashedMessage = keccak256(abi.encodePacked(kind,commitment,timeout));

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
        
        return ecrecover(prefixedHashMessage, sig.v, sig.r, sig.s);
    }

    function getCommitment(bytes32 paymentHash) external view returns (bytes32) {
        return commitments[paymentHash];
    }

    function balanceOf(address who, address token) external view returns (uint256) {
        return balances[who][token];
    }

    function myBalance(address token) external view returns (uint256) {
        return balances[msg.sender][token];
    }

    function deposit(address token, uint256 amount) external {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        balances[msg.sender][token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        uint256 balance = balances[msg.sender][token];
        require(balance>=amount, "Insufficient funds");

        TransferHelper.safeTransfer(token, msg.sender, amount);
        balances[msg.sender][token] = balance - amount;
    }

    //Initiate an invoice payment
    function offerer_payInvoice(AtomicSwapStruct calldata payReq) external returns(bytes32) {
        return offerer_payInvoice(payReq, false);
    }

    function offerer_payInvoice(AtomicSwapStruct calldata payReq, bool payIn) public returns(bytes32) {
        require(payReq.expiry > block.timestamp, "Request already expired");
        require(commitments[payReq.paymentHash]==bytes32(0x0), "Already commited");

        if(payIn) {
            TransferHelper.safeTransferFrom(payReq.token, msg.sender, address(this), payReq.amount);
        } else {
            uint256 balance = balances[msg.sender][payReq.token];
            require(balance >= payReq.amount, "Insufficient funds");
            balances[msg.sender][payReq.token] = balance - payReq.amount;
        }

        bytes32 commitment = keccak256(abi.encode(msg.sender, payReq));

        commitments[payReq.paymentHash] = commitment;

        emit PaymentRequest(msg.sender, payReq.intermediary, payReq.paymentHash, payReq);

        return commitment;
    }

    //Intiate a payment on behalf of user
    function offerer_payInvoice(address offerer, AtomicSwapStruct calldata payReq, uint64 timeout, Signature calldata signature) external returns(bytes32) {
        require(timeout>block.timestamp, "Expired");
        require(payReq.expiry > block.timestamp, "Request already expired");
        require(commitments[payReq.paymentHash]==bytes32(0x0), "Already commited");

        uint256 balance = balances[offerer][payReq.token];
        require(balance >= payReq.amount, "Insufficient funds");
        
        bytes32 commitment = keccak256(abi.encode(offerer, payReq));

        address sender = getAddress(commitment, timeout, signature, "payInvoice");
        require(offerer==sender, "Invalid signature");

        balances[sender][payReq.token] = balance - payReq.amount;

        commitments[payReq.paymentHash] = commitment;

        emit PaymentRequest(sender, payReq.intermediary, payReq.paymentHash, payReq);

        return commitment;
    }

    //Refund back to the offerer after enough time has passed, this can also be called by a third party service
    function offerer_refund(AtomicSwapStruct calldata payReq) external {
        offerer_refund(payReq, false);
    }

    function offerer_refund(AtomicSwapStruct calldata payReq, bool payOut) public {
        require(payReq.expiry<block.timestamp, "Not refundable, yet");
        bytes32 commitment = keccak256(abi.encode(msg.sender, payReq));
        require(commitments[payReq.paymentHash]==commitment, "Payment request not commited!");

        if(payOut) {
            TransferHelper.safeTransfer(payReq.token, msg.sender, payReq.amount);
        } else {
            balances[msg.sender][payReq.token] += payReq.amount;
        }

        commitments[payReq.paymentHash] = bytes32(0x0);

        emit Refunded(msg.sender, payReq.intermediary, payReq.paymentHash);
    }

    function _refundSingleNoSend(address offerer, AtomicSwapStruct calldata payReq, address token) private returns (uint256) {
        require(payReq.expiry<block.timestamp, "Not refundable, yet");
        require(payReq.token==token, "Invalid token in payment request");
        require(commitments[payReq.paymentHash]==keccak256(abi.encode(offerer, payReq)), "Payment request not commited!");

        commitments[payReq.paymentHash] = bytes32(0x00);

        emit Refunded(offerer, payReq.intermediary, payReq.paymentHash);

        return payReq.amount;
    }

    function offerer_refund_payInvoice(AtomicSwapStruct[] calldata payReqs, AtomicSwapStruct calldata newPayReq) external {
        require(commitments[newPayReq.paymentHash]==bytes32(0x00), "Invoice already paid or getting paid");

        uint256 totalLocked = 0;

        for(uint i=0;i<payReqs.length;i++) {
            totalLocked += _refundSingleNoSend(msg.sender, payReqs[i], newPayReq.token);
        }

        if(totalLocked>newPayReq.amount) {
            //One tx goes to dst, one back to msg.sender
            balances[msg.sender][newPayReq.token] += totalLocked-newPayReq.amount;
        } else if(totalLocked<newPayReq.amount) {
            uint256 currentBalance = balances[msg.sender][newPayReq.token];
            uint256 totalDebit = newPayReq.amount-totalLocked;
            require(currentBalance>=totalDebit, "Insufficient balance");
            balances[msg.sender][newPayReq.token] = currentBalance-totalDebit;
        }

        commitments[newPayReq.paymentHash] = keccak256(abi.encode(msg.sender, newPayReq));

        emit PaymentRequest(msg.sender, newPayReq.intermediary, newPayReq.paymentHash, newPayReq);
    }

    function _refundSingleNoSendNoRevert(address offerer, AtomicSwapStruct calldata payReq) private returns (uint256) {
        if(!(payReq.expiry<block.timestamp)) return 0; //Not refundable, yet
        if(!(commitments[payReq.paymentHash]==keccak256(abi.encode(offerer, payReq)))) return 0; //Payment request not commited!

        commitments[payReq.paymentHash] = bytes32(0x00);

        emit Refunded(offerer, payReq.intermediary, payReq.paymentHash);

        return payReq.amount;
    }

    //Payment requests must be ordered in a way that requests with the same token address will be grouped together, this is done to minimize the gas cost of running this function
    function offerer_refund(AtomicSwapStruct[] calldata payReqs) external {
        offerer_refund(payReqs, false);
    }
    
    function offerer_refund(AtomicSwapStruct[] calldata payReqs, bool payOut) public {
        uint256 totalLocked = 0;
        address currentToken = address(0x00);

        for(uint i=0;i<payReqs.length;i++) {
            if(currentToken!=payReqs[i].token && totalLocked>0) {
                if(payOut) {
                    TransferHelper.safeTransfer(currentToken, msg.sender, totalLocked);
                } else {
                    balances[msg.sender][currentToken] += totalLocked;
                }
                totalLocked = 0;
            }

            totalLocked += _refundSingleNoSendNoRevert(msg.sender, payReqs[i]);
            currentToken = payReqs[i].token;
        }

        if(totalLocked>0) {
            if(payOut) {
                TransferHelper.safeTransfer(currentToken, msg.sender, totalLocked);
            } else {
                balances[msg.sender][currentToken] += totalLocked;
            }
        }

    }

    //Refund back to offerer (effectively decline the payment reqest)
    function claimer_refundPayer(address offerer, AtomicSwapStruct calldata payReq) external {
        require(payReq.intermediary==msg.sender, "Incorrect intermediary");
        bytes32 commitment = keccak256(abi.encode(offerer, payReq));
        require(commitments[payReq.paymentHash]==commitment, "Payment request not commited!");

        balances[offerer][payReq.token] += payReq.amount;

        commitments[payReq.paymentHash] = bytes32(0x0);

        emit Refunded(offerer, payReq.intermediary, payReq.paymentHash);
    }

    function claimer_refundPayer(address offerer, AtomicSwapStruct calldata payReq, uint64 timeout, Signature calldata signature) external {
        claimer_refundPayer(offerer, payReq, timeout, signature, false);
    }

    function claimer_refundPayer(address offerer, AtomicSwapStruct calldata payReq, uint64 timeout, Signature calldata signature, bool payOut) public {
        bytes32 commitment = keccak256(abi.encode(offerer, payReq));
        
        address sender = getAddress(commitment, timeout, signature, bytes("refundPayer"));

        require(payReq.intermediary==sender, "Incorrect intermediary");
        require(commitments[payReq.paymentHash]==commitment, "Payment request not commited!");

        if(payOut) {
            TransferHelper.safeTransfer(payReq.token, offerer, payReq.amount);
        } else {
            balances[offerer][payReq.token] += payReq.amount;
        }

        commitments[payReq.paymentHash] = bytes32(0x0);

        emit Refunded(offerer, payReq.intermediary, payReq.paymentHash);
    }


    //Claim the funds in time providing a valid secret S
    function claimer_claim(address offerer, AtomicSwapStruct calldata payReq, bytes32 secret) external {
        claimer_claim(offerer, payReq, secret, true);
    }
    
    function claimer_claim(address offerer, AtomicSwapStruct calldata payReq, bytes32 secret, bool payOut) public {
        require(payReq.intermediary==msg.sender, "Incorrect intermediary");
        require(payReq.expiry>=block.timestamp, "Not claimable anymore"); //Not sure if this is necessary, but improves security for payer
        bytes32 commitment = keccak256(abi.encode(offerer, payReq));
        require(commitments[payReq.paymentHash]==commitment, "Payment request not commited!");

        require(payReq.paymentHash==sha256(abi.encodePacked(secret)), "Invalid secret");

        if(payOut) {
            TransferHelper.safeTransfer(payReq.token, msg.sender, payReq.amount);
        } else {
            balances[msg.sender][payReq.token] += payReq.amount;
        }
        commitments[payReq.paymentHash] = bytes32(uint256(0x01));

        emit Claimed(offerer, payReq.intermediary, payReq.paymentHash, secret);
    }

}