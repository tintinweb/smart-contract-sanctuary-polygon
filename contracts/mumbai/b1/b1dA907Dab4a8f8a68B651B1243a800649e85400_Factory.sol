// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
interface IERC20 {
    function admin() external view returns(address);
    function token(address _token) external view returns(uint256 trx_fee, uint256 aff_fee, uint256 arb_fee, bool status);
}

contract Escrow {
    address public super_admin; // default
    address public affiliation_address; // default
    address public arbitrator_address; // default
    address public fee_collector; // default
    address public  admin; // Deployer
    address public  factory_contract_address;
    uint64 public  withdrawal_period;
    uint64 public  delivery_period;
    uint64 public  inspection_period;
    uint64 public  extension_period;
    uint64 public  request_reply_period;
    uint64 public super_admin_claim_period = 60 * 60;  // in seconds
    uint64 public order_number = 1;
    uint64 public fees_paid_by;
    bool public pause;
    bool internal lock = false;

    struct Order {
        string order_desc;
        address buyer_address;
        bytes32 order_id;
        address token_address;
        uint256 amount;
        uint256 fee;
        uint64 feepaidby;
        uint256 time;
        Status status;
    }
    struct Token {
        uint256 trx_fee;
        uint256 aff_fee;
        uint256 arb_fee;
        bool status;
    }
    struct Settlement {
        uint256 percentage;
        bool by;
        uint256 requestTime;
        uint8 status;
    }
    struct Extension {
        bool by;
        bool accepted;
    }
    mapping(uint64 => Order) public orders;
    mapping(uint64 => uint64) public extension_time;
    mapping(bytes32 => uint64) public order_ids;
    mapping(address => Token) public tokens;
    mapping(uint64 => Settlement) public settlements;
    mapping(uint64 => Extension) public extensionRequests;

    enum Status {
	    NA, // Not exist
        IN, // Initialized 
        CA, // Canceled
        CO, // Completed
        ER, // Extended_Request 
        SD, // Settled
        AR, // Arbitration 
        FC  // Final_Claim
    }
    event NewOrder(bytes32 orderId, uint64 indexed orderNumber);
    event CancelOrder(uint64 indexed orderNumber);
    event CompleteOrder(uint64 indexed orderNumber);
    event SettlementRequest(uint64 indexed orderNumber);
    event SettlementRequestAccepted(uint64 indexed orderNumber, address by);
    event SettlementRequestRejected(uint64 indexed orderNumber, address by);
    event InspectionExtended(uint64 indexed orderNumber, address by);
    event InspectionRequestRejected(uint64 indexed orderNumber, address by);
    event DisputeCreated(uint64 indexed orderNumber, address by);
    event Claim(uint64[] orderNumbers);

    constructor(
        address _admin,
        address _fee_collector,
        address _arbitrator_address,
        address _affiliation_address,
        address[2] memory _tokens,
        uint64[6] memory times
    ) {
        admin = _admin;
        arbitrator_address = _arbitrator_address;
        fee_collector = _fee_collector;
        withdrawal_period = times[0]*60;    // in seconds
        delivery_period = times[1]*60;      // in seconds
        inspection_period = times[2]*60;    // in seconds
        extension_period = times[3]*60;     // in seconds
        request_reply_period = times[4]*60; // in seconds
        fees_paid_by = times[5];             // buyer(0) & seller(1)
        affiliation_address = _affiliation_address;
        factory_contract_address = msg.sender;
        super_admin = IERC20(factory_contract_address).admin();
        addToken(_tokens);
    }


    modifier isPause() {
        require(pause==false, "1001");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "1002");
        _;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == super_admin, "1003");
        _;
    }

    modifier validCaller(uint64 _order_num) {
        require(msg.sender == admin || orders[_order_num].buyer_address == msg.sender, "1004");
        _;
    }
    modifier validToken(address _token) {
        require (tokens[_token].status==true, "1005");
        _;
    }

    modifier onlyBuyer(uint64 _order_num) {
        require(orders[_order_num].buyer_address == msg.sender, "1006");
        _;
    }

    modifier validStatus(uint64 _order_num) {
        require(orders[_order_num].status == Status.ER || orders[_order_num].status == Status.IN , "1007");
        _;
    }

    modifier ReentrencyGuard() {
        require(!lock, "1008");
        lock = true;
        _;
        lock = false;
    }

    modifier validSettlement(uint64 _order_num) {
        require(settlements[_order_num].status == 0, "1009");
        require(block.timestamp < settlements[_order_num].requestTime + request_reply_period,"1010");
        require(msg.sender == orders[_order_num].buyer_address && settlements[_order_num].by == true
            || (msg.sender==admin && settlements[_order_num].by == false), "1011"); 
        _;
    }
    modifier validOrder(uint64 _order_num) {
        require(checkOrder(_order_num), "1012");
        _;
    }
    function checkOrder(uint64 _order_num) internal view returns (bool) {
        if(orders[_order_num].buyer_address == address(0))
            return false;
        else
            return true;
    }

    function addToken(address[2] memory _tokens) internal {
        for(uint i; i < _tokens.length; i++){
            if(tokens[_tokens[i]].status) {
                continue;
            }else {
            (uint256 trx_fee ,uint256 aff_fee, uint256 arb_fee, bool status)  = IERC20(factory_contract_address).token(_tokens[i]);
            require(status, "1013");
            tokens[_tokens[i]] = Token({
            trx_fee: trx_fee,
            aff_fee: aff_fee,
            arb_fee: arb_fee,
            status: status});
            }
        }
    }
    
    function calculateFee(address _token, uint256 _amount) internal view returns(uint256, uint256) {
        uint256 order_amount;
        uint256 order_fee;
        if(fees_paid_by == 0) {
            order_amount = (_amount*10000) / (tokens[_token].trx_fee+10000);
            order_fee = _amount - order_amount;
        } else {
            order_amount = _amount;
            order_fee = (_amount * tokens[_token].trx_fee) / 10000;
        }
        return (order_amount, order_fee);
    }

    function transfer(address _token, address _toAddress, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSignature("transfer(address,uint256)",_toAddress,_amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"1014");
    }
    function transferFrom(address _token, address _from, address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _from, _to, _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"1015");
    }

    function changeSuperAdmin(address _address) public onlySuperAdmin {
        super_admin = _address;
    }

    function changeArbitrator(address _address) public onlySuperAdmin {
        arbitrator_address = _address;
    }

    function changeAffiliate(address _address) public onlySuperAdmin {
        affiliation_address = _address;
    }

    function changeFeeCollector(address _address) public onlySuperAdmin {
        fee_collector = _address;
    }

    function changeSuperAdminClaimPeriod(uint64 _time) public onlySuperAdmin {
        super_admin_claim_period = _time * 60;
    }

    function changeConfig(address[] memory _tokens, bool[] memory _status, uint64 _fee_paid_by) external onlyAdmin {
        for(uint256 i; i<_tokens.length; i++) {
            if(tokens[_tokens[i]].trx_fee != 0){
                tokens[_tokens[i]].status = _status[i];
            }else{
                (uint256 trx_fee ,uint256 aff_fee, uint256 arb_fee,bool status)  = IERC20(factory_contract_address).token(_tokens[i]);
                require(status, "1016");
                tokens[_tokens[i]] = Token({
                trx_fee: trx_fee,
                aff_fee: aff_fee,
                arb_fee: arb_fee,
                status: true});
            }  
    	}
        fees_paid_by = _fee_paid_by;
    }
    
    function addOrderByToken(address _token, bytes32 _orderId, uint256 _orderAmount, string memory _description) 
    external isPause validToken(_token) {
        require(!checkOrder(order_ids[_orderId]), "1017");
        
        transferFrom(_token, msg.sender, address(this), _orderAmount);
        order_ids[_orderId] = order_number;
        (uint256 odr_amt , uint256 odr_fee ) = calculateFee(_token, _orderAmount);
        orders[order_number] = Order({
            order_desc: _description,
            buyer_address: msg.sender,
            token_address: _token,
            order_id: _orderId,
            amount: odr_amt,
            fee: odr_fee,
            time: block.timestamp,
            feepaidby: fees_paid_by,
            status: Status.IN
        });
        emit NewOrder(_orderId, order_number);
        order_number++;
    }

    function addOrder(bytes32 _orderId, string memory _description) external isPause payable {
        require(tokens[address(0)].status, "1018");
        require(!checkOrder(order_ids[_orderId]), "1019");
        
        (uint256 odr_amt , uint256 odr_fee ) = calculateFee(address(0), msg.value);

        order_ids[_orderId] = order_number;
        orders[order_number] = Order({
            order_desc: _description,
            buyer_address: msg.sender,
            token_address: address(0),
            order_id: _orderId,
            amount: odr_amt,
            fee: odr_fee,
            time: block.timestamp,
            feepaidby: fees_paid_by,
            status: Status.IN
        });
        emit NewOrder(_orderId, order_number);
        order_number++;
    }

    function getOrder(bytes32 _orderId) external view returns(uint256 orderNumber, Order memory) {
        return (order_ids[_orderId], orders[order_ids[_orderId]]);
    }

    function cancelOrder(uint64 _order_num) external isPause validCaller(_order_num) validOrder(_order_num) validStatus(_order_num) ReentrencyGuard {
        if(orders[_order_num].buyer_address == msg.sender){
            require(orders[_order_num].time + withdrawal_period > block.timestamp ,"1020");
        }else {
            require(orders[_order_num].time + withdrawal_period + delivery_period +inspection_period > block.timestamp, "1021");
        }
        uint256 amount = orders[_order_num].amount;
        if(orders[_order_num].feepaidby == 0){
            amount = orders[_order_num].amount + orders[_order_num].fee;
        }
        orders[_order_num].status = Status.CA;       
        if(orders[_order_num].token_address == address(0)) {
            payable(orders[_order_num].buyer_address).transfer(amount);
        } else {
            transfer(orders[_order_num].token_address, orders[_order_num].buyer_address, amount);
        }
        emit CancelOrder(_order_num);
    }

    function completeOrder(uint64 _order_num) external isPause validStatus(_order_num) onlyBuyer(_order_num) ReentrencyGuard {
        
        orders[_order_num].status = Status.CO;
        uint256  amt = orders[_order_num].amount;
        uint256  fee = orders[_order_num].fee;
        if(orders[_order_num].feepaidby ==1){
            amt = amt - fee;
        }
        if (orders[_order_num].token_address == address(0)) {
            if(affiliation_address != address(0)){
                uint256 affiliation = (fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100;
                fee = fee - affiliation;
                payable(affiliation_address).transfer(affiliation);
            }
            payable(admin).transfer(amt);
            payable(fee_collector).transfer(fee);
        }else{
            if(affiliation_address != address(0)){
                uint256 affiliation = ((orders[_order_num].fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100);
                fee = orders[_order_num].fee - affiliation; 
                transfer(orders[_order_num].token_address, affiliation_address, affiliation);
            }
            transfer(orders[_order_num].token_address, admin, amt);
            transfer(orders[_order_num].token_address, fee_collector, fee);
        }
        emit CompleteOrder(_order_num);
    }

    function settlementRequest(uint64 _order_num, uint256 _percentage) external isPause validOrder(_order_num) validStatus(_order_num){
        require(block.timestamp > orders[_order_num].time + withdrawal_period, "1022");
        require(settlements[_order_num].percentage == 0 || settlements[_order_num].status == 2, "1023");
        if (msg.sender == admin) {
            settlements[_order_num] = Settlement({
                percentage: _percentage,
                by: true,     // Request By Seller
                requestTime: block.timestamp,
                status: 0
            });
        } else if (orders[_order_num].buyer_address == msg.sender) {
            settlements[_order_num] = Settlement({
                percentage: _percentage,
                by: false,    // Request by buyer
                requestTime: block.timestamp,
                status: 0
            });
        } else {
            revert("forbidden");
        }
        emit SettlementRequest(_order_num);
    }
    function acceptSettlementRequest(uint64 _order_num) external isPause 
    validSettlement(_order_num)
    validStatus(_order_num)
    ReentrencyGuard {
        
        uint256 amt = orders[_order_num].amount;
        uint256 fee = orders[_order_num].fee;
        if(orders[_order_num].feepaidby == 1){
            amt = amt-fee;
        }
        uint256 refund = (amt * settlements[_order_num].percentage) / 100;
        uint256 remain = amt - refund;
        orders[_order_num].status = Status.SD;
        settlements[_order_num].status = 1;
        if(orders[_order_num].token_address == address(0)) {
            if(affiliation_address != address(0)){
                uint256 affiliation = (fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100;
                fee = fee - affiliation;
                payable(affiliation_address).transfer(affiliation);
            }
            payable(orders[_order_num].buyer_address).transfer(refund);
            payable(admin).transfer(remain);
            payable(fee_collector).transfer(fee);
        } else {
            address token_address = orders[_order_num].token_address;
            if(affiliation_address != address(0)){
                uint256 affiliation = (fee * (tokens[token_address].aff_fee)) / 10000;
                fee = fee - affiliation;
                transfer(token_address, affiliation_address, affiliation);
            }
            transfer(token_address, orders[_order_num].buyer_address, refund);
            transfer(token_address, admin, remain);
            transfer(token_address, fee_collector, fee);
        }
        emit SettlementRequestAccepted(_order_num, msg.sender);
    }
    function rejectSettlementRequest(uint64 _order_num) external isPause validSettlement(_order_num) {
        settlements[_order_num].status = 2;
        emit SettlementRequestRejected(_order_num, msg.sender);
    }
    
    function extendInspectionRequest(uint64 _order_num) external isPause validOrder(_order_num) validCaller(_order_num) {
        require(orders[_order_num].status == Status.IN, "1024");
        require(block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period +inspection_period, "1025");
        if(msg.sender == admin) {
            extensionRequests[_order_num] = Extension({
                by: true,
                accepted: true
            });
        } else {
            extensionRequests[_order_num] = Extension({
                by: false,
                accepted: true
            });
        }
        extension_time[_order_num] = extension_period;
        orders[_order_num].status = Status.ER;
        emit InspectionExtended(_order_num, msg.sender);
    }
    function rejectInspectionRequest(uint64 _order_num) external isPause validOrder(_order_num) onlyAdmin{
        require(orders[_order_num].status == Status.ER,"1026");
        extension_time[_order_num] = 0;
        extensionRequests[_order_num].accepted = false;
        orders[_order_num].status = Status.IN;
        emit InspectionRequestRejected(_order_num, msg.sender);
    }

    function addDispute(uint64 _order_num) external payable isPause validOrder(_order_num) validCaller(_order_num) validStatus(_order_num) ReentrencyGuard {
        require(msg.value >= tokens[orders[_order_num].token_address].arb_fee, "1027");
        require(block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period +inspection_period, "1028");

        payable(arbitrator_address).transfer(orders[_order_num].amount + msg.value);
        orders[_order_num].status = Status.AR;
        emit DisputeCreated(_order_num, msg.sender);
    }
    function addDisputeByToken(uint64 _order_num, uint256 _arb_fee) external isPause validOrder(_order_num) validCaller(_order_num) validStatus(_order_num) ReentrencyGuard {
        require(_arb_fee >= tokens[orders[_order_num].token_address].arb_fee, "1029");
        require(block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period +inspection_period, "1023");

        transfer(orders[_order_num].token_address, arbitrator_address, orders[_order_num].amount);
        transferFrom(orders[_order_num].token_address, msg.sender, arbitrator_address, _arb_fee);

        orders[_order_num].status = Status.AR;
        emit DisputeCreated(_order_num, msg.sender);
    }


    function claim(uint64[] calldata _order_nums) external isPause onlyAdmin ReentrencyGuard {
        for(uint64 i; i<_order_nums.length; i++) {
            uint64  _order_num = _order_nums[i];

            require(orders[_order_num].status == Status.ER || orders[_order_num].status == Status.IN, "1031"); 
            require(settlements[_order_num].percentage == 0, "1032");
            require(block.timestamp < orders[_order_num].time + withdrawal_period + delivery_period +inspection_period + extension_time[_order_num] , "1033");
            
            orders[_order_num].status = Status.CO;
            uint256  amt = orders[_order_num].amount;
            uint256  fee = orders[_order_num].fee;
            if(orders[_order_num].feepaidby==1){
                amt = orders[_order_num].amount - fee;
            }
            if (orders[_order_num].token_address == address(0)) {
                if(affiliation_address != address(0)){
                    uint256 affiliation = (fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100;
                    fee = fee - affiliation;
                    payable(fee_collector).transfer(affiliation);
                }
                payable(admin).transfer(amt);
                payable(fee_collector).transfer(fee);
            }else{
                if(affiliation_address != address(0)){
                    uint256 affiliation = ((orders[_order_num].fee * (tokens[orders[_order_num].token_address].aff_fee/100)) / 100);
                    fee = orders[_order_num].fee - affiliation; 
                    transfer(orders[_order_num].token_address, affiliation_address, affiliation);
                }
                transfer(orders[_order_num].token_address, admin, amt);
                transfer(orders[_order_num].token_address, fee_collector, fee);
            }
        }
        emit Claim(_order_nums);
    }

    function superClaim(uint64[] calldata _order_nums) external onlySuperAdmin ReentrencyGuard {
        for(uint64 i; i<_order_nums.length; i++) {
            uint64  _order_num = _order_nums[i];
            
            require(orders[_order_num].status == Status.ER || orders[_order_num].status == Status.IN, "1034"); 
            require(block.timestamp >= orders[_order_num].time
                        + withdrawal_period + delivery_period +inspection_period 
                        + extension_time[_order_num]
                        +  super_admin_claim_period
                    ,"1035");
            orders[_order_num].status = Status.FC;
            uint256 amt = orders[_order_num].amount;
            if(orders[_order_num].feepaidby == 0){
                amt = orders[_order_num].amount + orders[_order_num].fee;
            }
            if (orders[_order_num].token_address == address(0)) {
                payable(admin).transfer(amt);
            } else {
                transfer(orders[_order_num].token_address, super_admin, amt);
            }
        }
        emit Claim(_order_nums);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./Escrow.sol";

contract Factory {
    address public admin;
    address public arbitrator_address;
    address public fee_collector;
    bool public pause;
    
    struct Token {
        uint256 trx_fee;
        uint256 aff_fee;
        uint256 arb_fee;
    }
    mapping(address => Token) public token;
    mapping(address => bool) public status;
    event newEscrow (address contract_address);
    
    constructor( address _arbitrator_address, address _fee_collector) {
        arbitrator_address = _arbitrator_address;
        fee_collector = _fee_collector;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
    _;}
    modifier ValidToken(address _token) {
        require (status[_token]==true, "Invalid Token");
    _;}
    modifier isPause() {
        require(!pause, "This contract is Paused");
    _;}
    
    function togglePause() external onlyAdmin {
        pause = !pause;
    }
    function changeAdmin(address _address) external onlyAdmin {
        admin = _address;
    }
    function changeFeeCollector(address _address) external onlyAdmin {
        fee_collector = _address;
    }
    function addToken(address _token, uint256 _trx_fee, uint256 _aff_fee,uint256 _arb_fee) 
    external isPause onlyAdmin {
        require(token[_token].trx_fee == 0, "addToken failed");
        status[_token] = true;
        token[_token] = Token({
            trx_fee: _trx_fee,
            aff_fee: _aff_fee,
            arb_fee: _arb_fee
        });
    }
    function changeToken(address _token, uint256 _trx_fee, uint256 _aff_fee, uint256 _arb_fee, bool _status) 
    external isPause onlyAdmin ValidToken(_token) {
        status[_token] = _status; 
        token[_token] = Token({
            trx_fee: _trx_fee,
            aff_fee: _aff_fee,
            arb_fee: _arb_fee
        });
    }
    function toggleToken(address _token, bool _status) external onlyAdmin {
        status[_token] = _status;
    }
    function changeArbitrator(address _address) external onlyAdmin {
        arbitrator_address = _address;
    }

    function recoverTokens(address _token, uint256 _amount) external onlyAdmin {
        require(_token != address(0), "Invalid Token");
        (bool success, ) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", admin, _amount));
        require(success, "Transfer failed");
    }
    function recoverCoin () external payable onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }
        // times[0] = _withdrawal_period;
        // times[1] = _delivery_period;
        // times[2] = _inspection_period;
        // times[3] = _extension_period;
        // times[4] = _request_reply_period;
        // times[5] = _ffes_paid_by;
    function deployEscrowContract(
        address  _affiliation_address,
        address[2] memory _tokens,
        uint64[6] memory _times) external isPause {
            require(status[_tokens[0]] && status[_tokens[0]], "Invalid token");
        Escrow NewEscrow = new Escrow(
            msg.sender,
            fee_collector,
            arbitrator_address,
            _affiliation_address,
            _tokens,
            _times
        );
        emit newEscrow(address(NewEscrow));
    }
    fallback() external payable {

    }
    receive() external payable {
        
    }
}