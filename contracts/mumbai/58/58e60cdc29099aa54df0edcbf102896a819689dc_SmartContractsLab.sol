/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// Copyright (c) 2019-2021 Smart Contracts Lab
// SPDX-License-Identifier: UNLICENSED
// SCL mainnet contract (different from the SCL testnet contract)
pragma solidity ^0.8.0;

contract SmartContractsLab {
    //********************************************Global Variables********************************************************

    // SCLGross: balance accessible to owner
    uint public SCLGross;
    // Hash that identifies the ABI of the Mailbox function
    bytes4 constant SCL_Mailbox =
        bytes4(keccak256("Mailbox(uint32,int88,bool)"));
    //  Amount of gas reserved for the relay (net of the gas used to call the mailbox function)
    uint40 constant _gasForRelay = 40000;
    // Status outcome of multisig ResetPINPUK cal
    enum status {
        CLAIM,
        RESET,
        FAIL
    }
    status public Status;

    //*************************************************Structs************************************************************

    /** 
    @dev stores all sender addresses
    @param _PIN is the SCAs main address
    @param _PUK is the senders main address
    @param _PUK2a first of the PUK2 triplet. Is held by the sender
    @param _PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param _PUK2c third of the PUK2 triplet. Is held by the second trusted party
    */
    struct Sender {
        address payable _PIN;
        address payable _PUK;
        address _PUK2a;
        address _PUK2b;
        address _PUK2c;
    }

    /**
    @dev stores the msg.sender and the desired new Sender, needed for comparison reasons in the ResetPINPUK function
    @param _claimant is the address that called the ResetPINPUK function
    @param _newSender is the nested Sender struct
    */
    struct ResetPUK {
        address payable _claimant;
        Sender _newSender;
    }

    /**
    @dev stores the Commitment information
    @param SenderID uint that identifies a specific sender (is constant)
    @param _horizon the date until when a sender commits himself (in Unix epochtime, i.e., seconds since 01.01.1970)
    @param _senderFee stores the fee that is required
    @param _descriptionHash is the hashed description of the .pdf file
     */
    struct Commitment {
        int64 SenderID;
        uint32 _horizon;
        uint64 _senderFee;
        bytes32 _descriptionHash;
    }

    /**
    @dev stores the order information
    @param _deliveryAddress is the receivers address
    @param commitmentID int that identfies the senders most recent .pdf file
    @param _gasPrice uint that sets the max amount of transaction fees
    @param gasForDelivery Total gas amount for the Relay process 
    */
    struct OrderStruct {
        address payable _deliveryAddress;
        int64 commitmentID;
        uint64 _gasPrice;
        uint gasForDelivery;
    }

    //*************************************************Arrays*************************************************************

    /**
    @dev stores all Senders
    */
    Sender[] public senders;

    /**
    @dev stores all Commitments
    */
    Commitment[] public commitments;

    /**
    @dev stores all Orders
    */
    OrderStruct[] public orders;

    //*************************************************Mappings************************************************************

    /**
    @dev maps the PIN and PUK to a SenderID
    NOTE: ensures that 
        (i) Different SenderIDs have different PINs
        (ii) PINs are not used as PUKs
    */
    mapping(address => int64) public keyMap;

    /**
    @dev maps SenderID to ResetPUK
    NOTE: recalls existing claims of the ResetPINPUK function
    */
    mapping(int64 => ResetPUK) private resetIndex;

    //*************************************************Events************************************************************

    /**
    @dev provides information of a new sender to the website
    @param SenderID int64 that identifies a specific sender
    @param PIN is the main address
    @param PUK is the address to change the PIN address
    @param PUK2a first of the PUK2 triplet. Is held by the sender
    @param PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param PUK2c third of the PUK2 triplet. Is held by the second trusted party
     */
    event newSender(
        int64 SenderID,
        address payable PIN,
        address payable PUK,
        address PUK2a,
        address PUK2b,
        address PUK2c
    );

    /**
    @dev provides information of a changed PIN to the website
    @param SenderID uint that identifies a specific sender (is constant)
    @param newPIN alternative PIN for the deleted one
     */
    event PINChanged(int64 SenderID, address newPIN);

    /**
    @dev provides information about a reset of the PIN-PUK quintuple
    @param SenderID uint that identifies a specific sender
    @param PIN is the main address
    @param PUK is the address to change the PIN address
    @param PUK2a first of the PUK2 triplet. Is held by the sender
    @param PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param PUK2c third of the PUK2 triplet. Is held by the second trusted party
     */
    event resetPINPUK(
        int64 SenderID,
        address payable PIN,
        address payable PUK,
        address PUK2a,
        address PUK2b,
        address PUK2c,
        status Status
    );

    /**
    @dev provides information of a new commitment to the website
    @param SenderID uint that identifies a specific sender
    @param commitmentID uint that identfies the senders most recent .xlsx file
     */
    event newCommitment(int64 SenderID, int64 commitmentID);

    /**
    @dev provides information about the horizon extension to the website
    @param horizon is the new expire date 
    @param commitmentID int that identfies the senders most recent .xlsx file 
    */
    event horizonExtension(uint32 horizon, int64 commitmentID);

    /**
    @dev provides information of a new order to the website
    @param _PIN is the senders main address
    @param orderID uint that identifies a specific order
    @param commitmentID uint that identfies the senders most recent .xlsx file
    @param _location is the position (column and row) in the .xlsx file
    @param _orderDate date on which the order should arrive (in epochtime)
    @param _gasForDelivery is the total amount of gas that is available for the delivery process
    @param _gasPrice sets the gas Price for the delivery process
    @param receiverAddress is the address of the receiver 
     */
    event newOrder(
        address indexed _PIN,
        uint32 orderID,
        int64 commitmentID,
        string _location,
        uint32 _orderDate,
        uint40 _gasForDelivery,
        uint64 _gasPrice,
        address receiverAddress
    );

    /**
    @dev provides information of a changed _gasPrice to the website
    @param orderID uint that identifies a specific Order
    @param _newGasPrice is alternative _gasPrice for the deleted one
     */
    event gasPriceChanged(uint32 orderID, uint64 _newGasPrice);

    /**
    @dev provides information of the delivered data to the website
    @param orderID uint that identifies a specific order
    @param _statusFlag is a control variable that shows if the incoming transaction contains the datapoint
    @param _status shows whether the order is open or closed
     */
    event dataDelivered(uint32 orderID, bool _statusFlag, bool _status);

    /**
    @dev reports canceled orders
    @param orderID uint that identifies a specific order
     */
    event orderCanceled(uint32 orderID);

    /**
    @dev provides information about a fallback call
    @param AnyAddress is the address that called the fallback function
    @param MonetaryAmount is the msg.value that was provided with the call
     */
    event fallbackCall(address AnyAddress, uint MonetaryAmount);

    /**
    @dev provides information about a transfer
    @param AnyAddress is the address from which the funds were sent
    @param MonetaryAmount is the msg.value that was transferred
     */
    event receiveCall(address AnyAddress, uint MonetaryAmount);

    //++++++++++++++++++++++++++++++++++++++++++++++++++Start of the Account Management module++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
     The account management module consists of four functions:
    - NewSenderPro: Sets up a sender account using five EOAs (PIN, PUK, and PUK2 triplet)
    - NewSender: Sets up a sender account using two EOAs (PIN, PUK)
    - ChangePIN: Allows to change the PIN
    - ResetPINPUK: Allows to reset the sender account (keeping the SenderID)
    */

    /**
    @dev function register allows to set PIN, PUK and PUK2 triplet, thereby creating the SenderID
    @dev SenderID is >=0 for registrations in the mainnet (and <0 for registrations in the testnet)
    @dev this function has to be called via the PUK address
    @param _PIN is the SCAs main address
    @param _PUK is the senders main address
    @param _PUK2a first of the PUK2 triplet. Is held by the sender
    @param _PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param _PUK2c third of the PUK2 triplet. Is held by the second trusted party
    */
    function NewSenderPro(
        address payable _PIN,
        address payable _PUK,
        address _PUK2a,
        address _PUK2b,
        address _PUK2c
    ) public returns (int64) {
        //Checks if the function caller is the PUK
        require(msg.sender == _PUK, "Must be called from PUK");
        //checks that the PUK, PUK2a, PUK2b and PUK2c are different addresses than the PIN Adress
        require(
            _PIN != _PUK && _PIN != _PUK2a && _PIN != _PUK2b && _PIN != _PUK2c,
            "PIN can't be PUK/PUK2a/PUK2b/PUK2c"
        );
        //Checks if the PIN is already in use
        require(keyMap[_PIN] == 0x0, "PIN already in use");
        //Checks if the PUK is already in use
        require(keyMap[_PUK] == 0x0, "PUK already in use");
        //creates SenderID and stores the sender information
        int64 SenderID = int64(int(senders.length));
        senders.push(Sender(_PIN, _PUK, _PUK2a, _PUK2b, _PUK2c));
        //create dependency PIN / PUK -> SenderID
        keyMap[_PIN] = SenderID;
        keyMap[_PUK] = SenderID;
        //create dependency PIN / PUK -> SenderID
        //sends information of a new sender to the website
        emit newSender(SenderID, _PIN, _PUK, _PUK2a, _PUK2b, _PUK2c);
        return (SenderID);
    }

    /**
    @dev function registers new senders within a lower security level using the PUK address as PUK und PUK2 triplet
    @param _PIN is the SCAs main address
    @param _PUK is the senders main address
     */
    function NewSender(
        address payable _PIN,
        address payable _PUK
    ) external returns (int64) {
        int64 SenderID = NewSenderPro(_PIN, _PUK, _PUK, _PUK, _PUK);
        return (SenderID);
    }

    /**
    @dev to change the PIN address
    @dev has to be called by the PUK
    @param _newPIN alternative PIN for the deleted one
    */
    function ChangePIN(address payable _newPIN) external {
        // 1. Authentication
        int64 senderID = keyMap[msg.sender];
        Sender storage s = senders[uint(int(senderID))];
        require(msg.sender == s._PUK, "Invalid PUK");

        // 2. Formal check of PIN
        require(
            s._PUK2a != _newPIN && s._PUK2b != _newPIN && s._PUK2c != _newPIN,
            "Can't use PUK2a/PUK2b/PUK2c as PIN"
        );
        //requires that the PIN is not already in use => implies that the newPIN is not equal to the PUK or belongs to another sender
        require(keyMap[_newPIN] == 0x0, "PIN already in use");

        // 3. Documentation
        keyMap[s._PIN] = 0x0;
        s._PIN = _newPIN;
        keyMap[_newPIN] = senderID;
        emit PINChanged(senderID, _newPIN);
    }

    //formal correctness of the ResetPINPUK function doesnt get checked enough thoroughly...
    function ResetPINPUK(
        int64 SenderID,
        address payable _newPIN,
        address payable _newPUK,
        address _newPUK2a,
        address _newPUK2b,
        address _newPUK2c
    ) external returns (status) {
        require(SenderID >= 0, "Must be a SenderID >= 0");
        Sender storage s = senders[uint(int(SenderID))];
        ResetPUK storage r = resetIndex[SenderID];

        // 1. Authentication
        require(
            (msg.sender == s._PUK2a) ||
                (msg.sender == s._PUK2b) ||
                (msg.sender == s._PUK2c),
            "Not authorized"
        );

        // 2. Check formal correctness
        require(
            _newPIN != _newPUK &&
                _newPIN != _newPUK2a &&
                _newPIN != _newPUK2b &&
                _newPIN != _newPUK2c,
            "PIN already used"
        );

        // 3. Further Authentication
        require(msg.sender != r._claimant, "Use another PUK2");

        // 4. Case distinction
        // if no claim exists create one
        if (r._claimant == address(0)) {
            // handle case where PUK and PUK2 triplet are the same

            if (
                s._PUK == s._PUK2a && s._PUK == s._PUK2b && s._PUK == s._PUK2c
            ) {
                keyMap[s._PIN] = 0x0;
                keyMap[s._PUK] = 0x0;
                s._PIN = _newPIN;
                s._PUK = _newPUK;
                keyMap[_newPIN] = SenderID;
                keyMap[_newPUK] = SenderID;
                s._PUK2a = _newPUK2a;
                s._PUK2b = _newPUK2b;
                s._PUK2c = _newPUK2c;
                resetIndex[SenderID] = ResetPUK(
                    payable(address(0)),
                    Sender(
                        payable(address(0)),
                        payable(address(0)),
                        address(0),
                        address(0),
                        address(0)
                    )
                );
                emit resetPINPUK(
                    SenderID,
                    _newPIN,
                    _newPUK,
                    _newPUK2a,
                    _newPUK2b,
                    _newPUK2c,
                    status.RESET
                );
                return status.RESET;
            }

            r._claimant = payable(msg.sender);
            r._newSender._PIN = _newPIN;
            r._newSender._PUK = _newPUK;
            r._newSender._PUK2a = _newPUK2a;
            r._newSender._PUK2b = _newPUK2b;
            r._newSender._PUK2c = _newPUK2c;
            emit resetPINPUK(
                SenderID,
                _newPIN,
                _newPUK,
                _newPUK2a,
                _newPUK2b,
                _newPUK2c,
                status.CLAIM
            );
            return status.CLAIM;
        }
        //if claim exists and addresses are the same then reset
        else if (
            _newPIN == r._newSender._PIN &&
            _newPUK == r._newSender._PUK &&
            _newPUK2a == r._newSender._PUK2a &&
            _newPUK2b == r._newSender._PUK2b &&
            _newPUK2c == r._newSender._PUK2c
        ) {
            keyMap[s._PIN] = 0x0;
            keyMap[s._PUK] = 0x0;
            s._PIN = _newPIN;
            s._PUK = _newPUK;
            keyMap[_newPIN] = SenderID;
            keyMap[_newPUK] = SenderID;
            s._PUK2a = _newPUK2a;
            s._PUK2b = _newPUK2b;
            s._PUK2c = _newPUK2c;
            resetIndex[SenderID] = ResetPUK(
                payable(address(0)),
                Sender(
                    payable(address(0)),
                    payable(address(0)),
                    address(0),
                    address(0),
                    address(0)
                )
            );
            emit resetPINPUK(
                SenderID,
                _newPIN,
                _newPUK,
                _newPUK2a,
                _newPUK2b,
                _newPUK2c,
                status.RESET
            );
            return status.RESET;
        }
        // if claim exists but addresses are not the same, then fail
        else {
            resetIndex[SenderID] = ResetPUK(
                payable(address(0)),
                Sender(
                    payable(address(0)),
                    payable(address(0)),
                    address(0),
                    address(0),
                    address(0)
                )
            );
            emit resetPINPUK(
                SenderID,
                _newPIN,
                _newPUK,
                _newPUK2a,
                _newPUK2b,
                _newPUK2c,
                status.FAIL
            );
            return status.FAIL;
        }
    }

    //-----------------------------------------------End of the Account Management module-----------------------------------------------------

    //++++++++++++++++++++++++++++++++++++++++++++++++++Start of the Commitment module+++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
    The Commitment module consists of two functions:
    - NewCommitment: Registers new commitments
    - HorizonExtension: Extends the DICs commitment horizon
    */

    /**
    @dev sets up new commitments for .xlsx files
    @param SenderID uint that identifies a specific sender (is constant)
    @param _horizon the date until when a sender commits himself (in epochtime)
    @param _senderFee sets the fee that is required to be paid within the order process
    @param _descriptionHash sets the identification parameter for the commited data
     */
    function NewCommitment(
        int64 SenderID,
        uint32 _horizon, // example future timestamp: 4000000000
        uint64 _senderFee,
        bytes32 _descriptionHash // example hash: 0x54a6483b8aca55c9df2a35baf71d9965ddfd623468d81d51229bd5eb7d1e1c1b
    ) external returns (int64) {
        // TODO get senderID via msg.sender and keymap
        require(SenderID >= 0, "Must be a SenderID >=0");
        require(
            msg.sender == senders[uint(int(SenderID))]._PUK,
            "Invalid PUK for senderID"
        );
        require(_horizon >= block.timestamp, "Horizon must be in the future");

        int64 commitmentID = int64(int(commitments.length));
        commitments.push(
            Commitment(SenderID, _horizon, _senderFee, _descriptionHash)
        );

        emit newCommitment(SenderID, commitmentID);
        return (commitmentID);
    }

    /**
    @dev extends the senders commitment
    @param commitmentID uint that identfies the senders most recent .xlsx file  -> here that ID should be chosen the sender wishes to extend
    @param _newHorizon the date until when a sender commits himself (in epochtime)
     */
    function HorizonExtension(int64 commitmentID, uint32 _newHorizon) external {
        // 1. Authentication
        require(commitmentID > 0, "Must be a commitmentID > 0");
        Commitment storage c = commitments[uint(int(commitmentID))];
        require(
            msg.sender == senders[uint(int(c.SenderID))]._PUK,
            "Invalid PUK"
        );

        // 2. Formal correctness
        require(_newHorizon >= c._horizon, "New date before old date");

        // 3. Changing to the new horizon
        c._horizon = _newHorizon;
        emit horizonExtension(c._horizon, commitmentID);
    }

    //-----------------------------------------------------End of the Commitments module-------------------------------------------------------

    //+++++++++++++++++++++++++++++++++++++++++++++++Start of the Order & Delivery module++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
    The order & delivery module consists of five functions:
    - GetTransactionCosts: Computes the transaction costs
    - Order: Used to order content from the oracle 
    - ChangeGasPrice: Changes the gas price
    - Relay: Receives the content from the sender, forwards it to the receiver, and does the accounting
    - CancelOrder: Cancels an unfilled order
    */

    // This function allows the receiver to determine the value that needs to be attached to the order transaction
    function GetTransactionCosts(
        int64 _commitmentID,
        uint40 _gasForMailbox,
        uint _gasPriceInGWei
    ) external view returns (uint) {
        require(_commitmentID > 0, "Must be a commitmentID > 0");
        //convert to wei
        require(
            _commitmentID < int64(int(commitments.length)),
            "Invalid commitmentID"
        );
        uint _senderFee = commitments[uint(int(_commitmentID))]._senderFee;
        //_gasPriceInGWei * 1e9 converts _gasPriceInGwei to Wei
        return
            uint(
                (_gasForMailbox + _gasForRelay) *
                    _gasPriceInGWei *
                    1e9 +
                    _senderFee
            );
    }

    /**
    @dev general order function for customized orders
    @param commitmentID int64 that identifies a specific commitment
    @param _query the query string to be executed
    @param _orderDate date on which the order should arrive (in epochtime)
    @param _gasForMailbox is the maximum of gas that is available for the delivery process (set by the receiver)
    @param _gasPrice The gasPrice for the delivery transaction
     */

    /**
    @dev receives the final data and collects the fee
    @param orderID uint that identifies a specific order
    @param _data is the finally requested information behind the order
    @param _statusFlag is a control variable that shows if the incoming transaction contains the datapoint
     */

    function Relay(
        uint32 orderID,
        int88 _data,
        bool _statusFlag
    ) public payable {
        // 1. On-chain authentication
        OrderStruct memory o = orders[orderID];
        Commitment memory c = commitments[uint(int(o.commitmentID))];
        require(o._deliveryAddress != address(0), "Order already delivered");
        //require(msg.sender == senders[uint(int(c.SenderID))]._PIN, "Not authorized"); // take out for automatic calling of Relay function from OrderRandomNumber
        // 2. Compensation
        uint64 fee = c._senderFee;
        uint reimbursement = 0;
        if (_statusFlag) {
            senders[uint(int(c.SenderID))]._PUK.transfer(fee / 2);
            SCLGross += fee / 2; // SCL keeps half the sender fee
        } else {
            reimbursement = fee;
        }
        // 3. Delivery
        delete orders[orderID];
        (bool sent, ) = o._deliveryAddress.call{value: reimbursement}(
            abi.encodeWithSelector(SCL_Mailbox, orderID, _data, _statusFlag)
        );
        emit dataDelivered(orderID, _statusFlag, sent);
    }

    function Order(
        int64 commitmentID,
        string calldata _query,
        uint32 _orderDate,
        uint40 _gasForMailbox,
        uint64 _gasPrice
    ) external payable returns (uint32) {
        // convert Gwei to wei
        _gasPrice = _gasPrice * 1e9;

        // 1. Order analysis
        require(commitmentID > 0, "Must be a commitmentID > 0");
        require(
            commitmentID < int64(int(commitments.length)),
            "Invalid commitmentID"
        );
        Commitment memory c = commitments[uint(int(commitmentID))];
        uint32 OrderID = uint32(orders.length);
        uint40 _gasForDelivery = _gasForMailbox + _gasForRelay;
        uint _gasCost = _gasForDelivery * _gasPrice;
        int delta = int(msg.value) - int(_gasCost + c._senderFee);
        if (delta > 0) {
            SCLGross += uint(delta);
        }

        // 2. Checking incoming order
        require(delta >= 0, "Insufficient gas for relay");

        // 3. Reporting to website
        address payable PIN = senders[uint(int(c.SenderID))]._PIN;
        emit newOrder(
            PIN,
            OrderID,
            commitmentID,
            _query,
            _orderDate,
            _gasForDelivery,
            _gasPrice,
            msg.sender
        );

        // 4. Fueling delivery
        PIN.transfer(_gasCost);

        // 5. Storing order
        orders.push(
            OrderStruct(
                payable(msg.sender),
                commitmentID,
                _gasPrice,
                _gasForDelivery
            )
        );
        return (OrderID);
    }

    /**
    @dev to change the _gasPrice of a order
    @dev has to be called by the PUK
    @param _newGasPrice is the new _gasPrice for the Sender
    */
    function ChangeGasPrice(
        uint64 _newGasPrice,
        uint32 orderID
    ) external payable {
        OrderStruct storage order = orders[uint32(orderID)];
        require(
            msg.sender == order._deliveryAddress,
            "Not address of receiver contract"
        ); // This will only allow the receiver contract to change the gasPrice not necessarily the receiver
        _newGasPrice = _newGasPrice * 1e9;
        uint oldGasPrice = order._gasPrice;
        order._gasPrice = _newGasPrice;
        address payable senderPIN = senders[
            uint(int(commitments[uint(int(order.commitmentID))].SenderID))
        ]._PIN;
        if (_newGasPrice > oldGasPrice) {
            uint toTransfer = order.gasForDelivery *
                (_newGasPrice - oldGasPrice);
            require(msg.value >= toTransfer, "Gas price too low");
            senderPIN.transfer(toTransfer);
        }
        emit gasPriceChanged(orderID, _newGasPrice);
    }

    /**
    @dev cancels unfilled order
    @param orderID that identifies a specific order
    */
    function CancelOrder(uint32 orderID) external payable {
        require(
            orders[orderID]._deliveryAddress != address(0),
            "Order does not exist or is already filled"
        );
        require(
            orders[orderID]._deliveryAddress == msg.sender,
            "Not from receiver's contract"
        );
        payable(msg.sender).transfer(
            commitments[uint(int(orders[orderID].commitmentID))]._senderFee
        );
        emit orderCanceled(orderID);
        delete orders[orderID];
    }

    //------------------------------------------------End of the Order & Delivery module-------------------------------------------------------

    //+++++++++++++++++++++++++++++++++++++++++++++++Start of the Contract Governance module++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
    The contract governance module consists of four functions:
    - Constructor: Authentication and initial registrations
    - Fallback: Recommended
    - Receive: Recommended
    - Collect: Transfers any positive balance to the owner's address
    */

    constructor(
        address payable _PIN,
        address _PUK2a,
        address _PUK2b,
        address _PUK2c
    ) {
        // Initial registration: SCL (SenderID-0)
        senders.push(Sender(_PIN, payable(msg.sender), _PUK2a, _PUK2b, _PUK2c));
        keyMap[_PIN] = 0;
        keyMap[msg.sender] = 0;

        // Initial commitment: The SCL owner and Website (void commitment, fill in 0) (senderID-0)
        commitments.push(Commitment(0, 0, 0, 0));
    }

    /**
    @dev Fallback responds to unknown function call
    */
    fallback() external payable {
        SCLGross += msg.value;
        emit fallbackCall(msg.sender, msg.value);
    }

    /**
    @dev Receive responds to any transfers
    */
    receive() external payable {
        SCLGross += msg.value;
        emit receiveCall(msg.sender, msg.value);
    }

    /**
    @dev transfers all collected payments from this contract to the owner
    */
    function Collect() external {
        require(msg.sender == senders[0]._PUK, "Not authorized");
        senders[0]._PUK.transfer(SCLGross);
        SCLGross = 0;
    }

    //----------------------------------------------End of the Contract Governance module------------------------------------------------------

    //+++++++++++++++++++++++++++++++++++++++++++++++Start of the Contract Information Module++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
    The contract information module simplifies the interaction with the backend
    It consists of five view functions
    - GetSenderID
    - GetPIN
    - GetPUK
    - GetSenderInformation
    - GetReceiverFromOrderID
    */

    /**
    @dev determines the SenderID via the address (PIN or PUK)
    @dev the possibility to easlily get your SenderID increases the sender convenience
    @dev is needed for testing purposes, you have to kblock.timestamp the SenderID
     */
    function GetSenderID() external view returns (int64) {
        return (keyMap[msg.sender]);
    }

    /**
    @dev returns the PIN of a SenderID
     */
    function GetPIN(int64 SenderID) public view returns (address payable) {
        require(SenderID >= 0, "Must be a SenderID >= 0");
        Sender storage s = senders[uint(int(SenderID))];
        return (s._PIN);
    }

    /**
    @dev returns the PUK of a SenderID
     */
    function GetPUK(int64 SenderID) public view returns (address payable) {
        require(SenderID >= 0, "Must be a SenderID >= 0");
        Sender storage s = senders[uint(int(SenderID))];
        return (s._PUK);
    }

    /**
    @dev returns the entire sender struct
    @dev has to be called by the PUK
    @dev is needed for testing purposes (backend) you have to check whether PIN and/or PUK got changed
    @param SenderID uint that identifies a specific sender (is constant)
     */
    function GetSenderInformation(
        int64 SenderID
    ) public view returns (address, address, address, address, address) {
        require(SenderID >= 0, "Must be a SenderID >= 0");

        require(
            msg.sender == senders[0]._PIN ||
                msg.sender == senders[uint(int(SenderID))]._PUK,
            "Not authorized"
        );

        Sender storage s = senders[uint(int(SenderID))];
        return (s._PIN, s._PUK, s._PUK2a, s._PUK2b, s._PUK2c);
    }

    /**
    @dev necessary to be able to display the receiver address on our webpage
    @param orderID uint that identifies a specific order (is constant)
     */
    function GetReceiverFromOrderID(
        uint32 orderID
    ) public view returns (address) {
        require(msg.sender == senders[0]._PIN, "Not authorized");
        return (orders[orderID]._deliveryAddress);
    }

    //-----------------------------------------------End of the of the Contract Information Module-----------------------------------------------------
}
//--------------------------------------------------------End of Contract------------------------------------------------------------------