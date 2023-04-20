/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Bet {
    address Admin;
    address payable refund_add;
    address payable [] participant_add;
    address payable [] participant_addA;
    address payable [] participant_addB;
    mapping(address => uint) balancesA_record;
    mapping(address => uint) balancesB_record;
    mapping(address => uint) settle_record;
    mapping(address => uint) balancesA;
    mapping(address => uint) balancesB;
    string question;
    string option1;
    string option2;
    string result;
    struct Question_Record{
        address payable [] participant_add;
        address payable [] participant_addA;
        address payable [] participant_addB;
        string question;
        string option1;
        string option2;
        string result;        
        uint question_no;
        uint endTime;
        uint totalA;
        uint totalB;
        uint total;
        uint status;
        uint margin;
    }
    struct Question_Record_Balances{
        mapping(address => uint) balancesA_record;
        mapping(address => uint) balancesB_record;
        mapping(address => uint) settle_record;
        mapping(address => uint) balancesA;
        mapping(address => uint) balancesB;
    }
    Question_Record [] question_records;
    Question_Record_Balances [] question_records_balances;
    uint margin;
    uint question_no;
    uint amount;
    uint total;
    uint repeat;
    uint repeatA;
    uint repeatB;
    uint endTime;
    uint totalA;
    uint totalB;
    uint status;
    uint max_question;
    uint [] settle_time;
    uint [] settle_status;
    uint [] question_end;

    IERC20 public usdt; //要先在Dapp調用usdt合約中的approve函數，approve函數不是在智能合約中調用的
    
    constructor() {
        Admin = msg.sender;
        question_no=0;
        max_question=question_no;
        usdt = IERC20(address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F));
    }

    function comparefunction(string memory _result) internal pure returns (uint toSelection){
        if (keccak256(abi.encodePacked(_result))==keccak256(abi.encodePacked("OptionA"))){
            toSelection=1;
        }else if (keccak256(abi.encodePacked(_result))==keccak256(abi.encodePacked("OptionB"))){
            toSelection=2;
        }else if (keccak256(abi.encodePacked(_result))==keccak256(abi.encodePacked("Draw/Cancel"))){
            toSelection=3;
        }else{
            toSelection=0;
        }
    }

    function input_question(string memory _question, string memory _option1 , string memory _option2, uint _endTime, uint _margin) public check_description{
        question_no=question_no+1;
        question=_question;
        option1=_option1;
        option2=_option2;
        endTime=_endTime;
        max_question=question_no;
        status=1;
        settle_status.push(1);
        settle_time.push(0);
        question_end.push(endTime);
        margin=_margin;
        Question_Record memory question_record=Question_Record(participant_add, participant_addA, participant_addB, question, option1, option2, result, question_no, endTime, totalA, totalB, total, status, margin);  //20230201
        question_records.push(question_record);
        question_records_balances.push();
    }

    function return_contract_details() public view returns(address){
        return (address(this));
    }

    function return_max_question() public view returns(uint){
        return (max_question);
    }

    function return_settle_record() public view returns(uint [] memory, uint [] memory, uint [] memory){
        return (settle_time, settle_status, question_end);
    }
    
    function return_question_details_one(uint _question_no) public view returns(string memory, string memory, string memory, string memory, uint, uint){
        string memory output_question=question_records[_question_no-1].question;
        string memory output_option1=question_records[_question_no-1].option1;
        string memory output_option2=question_records[_question_no-1].option2;
        string memory output_result=question_records[_question_no-1].result;
        uint output_status=question_records[_question_no-1].status;
        uint output_endTime=question_records[_question_no-1].endTime;
        return (output_question, output_option1, output_option2, output_result, output_status, output_endTime);
    }

    function return_question_details_two(uint _question_no) public view returns(uint, uint, uint, uint, uint){
        uint output_totalA=question_records[_question_no-1].totalA;
        uint output_totalB=question_records[_question_no-1].totalB;
        uint output_participant_addA_no=question_records[_question_no-1].participant_addA.length;
        uint output_participant_addB_no=question_records[_question_no-1].participant_addB.length;
        uint output_margin=question_records[_question_no-1].margin;
        return (output_totalA, output_totalB, output_participant_addA_no, output_participant_addB_no, output_margin);
    }

    function return_client_balances(uint _question_no, address _clientadd) public view returns(uint, uint, uint){
        uint client_balancesA=question_records_balances[_question_no-1].balancesA_record[_clientadd];
        uint client_balancesB=question_records_balances[_question_no-1].balancesB_record[_clientadd];
        uint client_get=question_records_balances[_question_no-1].settle_record[_clientadd];
        return (client_balancesA, client_balancesB, client_get);
    }
 
    function betA(uint _question_no, uint _amount) payable public check_betac(_question_no){
        //payable(address(this)).transfer(msg.value);
        usdt.transferFrom(msg.sender, address(this), _amount);
        question_records[_question_no-1].totalA+=_amount;
        question_records[_question_no-1].total+=_amount;
        if (question_records_balances[_question_no-1].balancesA[msg.sender]==0 && question_records_balances[_question_no-1].balancesB[msg.sender]==0){
            question_records[_question_no-1].participant_add.push(msg.sender);
            question_records[_question_no-1].participant_addA.push(msg.sender);
        }else if(question_records_balances[_question_no-1].balancesA[msg.sender]==0){
            question_records[_question_no-1].participant_addA.push(msg.sender);
        }
        question_records_balances[_question_no-1].balancesA[msg.sender]+=_amount;
        question_records_balances[_question_no-1].balancesA_record[msg.sender]+=_amount;
    }

    function betB(uint _question_no, uint _amount) payable public check_betac(_question_no){
        //payable(address(this)).transfer(msg.value);
        usdt.transferFrom(msg.sender, address(this), _amount);
        question_records[_question_no-1].totalB+=_amount;
        question_records[_question_no-1].total+=_amount;
        if (question_records_balances[_question_no-1].balancesA[msg.sender]==0 && question_records_balances[_question_no-1].balancesB[msg.sender]==0){
            question_records[_question_no-1].participant_add.push(msg.sender);
            question_records[_question_no-1].participant_addB.push(msg.sender);
        }else if(question_records_balances[_question_no-1].balancesB[msg.sender]==0){
            question_records[_question_no-1].participant_addB.push(msg.sender);
        }
        question_records_balances[_question_no-1].balancesB[msg.sender]+=_amount;
        question_records_balances[_question_no-1].balancesB_record[msg.sender]+=_amount;
    }


    function settle(string memory _result, uint _question_no) payable public check_inputresult(_result, _question_no) {
        question_records[_question_no-1].result=_result;
        uint settlemargin=question_records[_question_no-1].margin;
        if (comparefunction(question_records[_question_no-1].result)==1){
            amount=0;
            for(uint i = 0; i < question_records[_question_no-1].participant_addA.length; i++){
                refund_add=question_records[_question_no-1].participant_addA[i];
                amount=(question_records_balances[_question_no-1].balancesA[refund_add]*question_records[_question_no-1].totalB/question_records[_question_no-1].totalA+question_records_balances[_question_no-1].balancesA[refund_add])*(100-settlemargin)/100;
                question_records_balances[_question_no-1].settle_record[refund_add]=amount;
                delete question_records_balances[_question_no-1].balancesA[refund_add];
                delete question_records_balances[_question_no-1].balancesB[refund_add];
                question_records[_question_no-1].total-=amount;
                usdt.transfer(refund_add, amount);
                //refund_add.transfer(amount);
            }
        }else if (comparefunction(question_records[_question_no-1].result)==2){
            amount=0;
            for(uint i = 0; i < question_records[_question_no-1].participant_addB.length; i++){
                refund_add=question_records[_question_no-1].participant_addB[i];
                amount=(question_records_balances[_question_no-1].balancesB[refund_add]*question_records[_question_no-1].totalA/question_records[_question_no-1].totalB+question_records_balances[_question_no-1].balancesB[refund_add])*(100-settlemargin)/100;
                question_records_balances[_question_no-1].settle_record[refund_add]=amount;
                delete question_records_balances[_question_no-1].balancesA[refund_add];
                delete question_records_balances[_question_no-1].balancesB[refund_add];
                question_records[_question_no-1].total-=amount;
                usdt.transfer(refund_add, amount);
                //refund_add.transfer(amount);
            }
        } else if (comparefunction(question_records[_question_no-1].result)==3){
            amount=0;
            for(uint i = 0; i < question_records[_question_no-1].participant_add.length; i++){
                refund_add=question_records[_question_no-1].participant_add[i];
                amount=question_records_balances[_question_no-1].balancesA[refund_add]+question_records_balances[_question_no-1].balancesB[refund_add];
                question_records_balances[_question_no-1].settle_record[refund_add]=amount;
                delete question_records_balances[_question_no-1].balancesA[refund_add];
                delete question_records_balances[_question_no-1].balancesB[refund_add];
                question_records[_question_no-1].total-=amount;
                usdt.transfer(refund_add, amount);
                //refund_add.transfer(amount);
            }
        }
        amount=question_records[_question_no-1].total;
        question_records[_question_no-1].status=0;
        question_records[_question_no-1].total=0;
        usdt.transfer(msg.sender, amount);
        //msg.sender.transfer(amount);
	    settle_time[_question_no-1]=block.timestamp;
	    settle_status[_question_no-1]=0;
    }

    modifier check_betac(uint _question_no){
        require(question_records[_question_no-1].endTime>=block.timestamp, "Timed out");
        require(question_records[_question_no-1].status==1, "Betting terminated.");
        require(msg.sender != Admin, "Admin can't bet.");
        _;
    }
    
    modifier check_description{
        require(msg.sender == Admin, "Only Admin can input question.");
        _;
    }

    modifier check_inputresult(string memory _result, uint _question_no){
        require(comparefunction(_result)==1 || comparefunction(_result)==2 || comparefunction(_result)==3, "Input wrong.");
        require(msg.sender == Admin, "Only Admin can settle.");
        require(question_records[_question_no-1].status==1, "Already settled.");
        _;
    }
    
    fallback() external payable {}
    receive() external payable {}
}