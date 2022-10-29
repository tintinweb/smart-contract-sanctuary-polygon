/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract GB {
    address public owner;
    address referee;
    address hoster;

    string gamename;
    uint256 total_gameID;
    uint256 gameID;

    uint256 public time_lock;
    uint256 public time_dead;

    uint256 hoster_fee;
    uint256 referee_fee;

    address new_game;
    mapping (uint256 => address) public match_GAME;    


    constructor (){
        owner = msg.sender;
        total_gameID = 0;
        //預設REFEREE
        referee = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied. onlyOwner");
        _;
    }

    modifier onlyReferee() {
        require(msg.sender == referee,"Permission denied. onlyReferee");
        _;
    }

    modifier onlyHoster() {
        require(msg.sender == hoster,"Permission denied. onlyHorster");
        _;
    }

    function create_new_game (
        string memory _set_gamename,uint256 _hoster_fee_thousandth,
        uint256 _time_lock,uint256 _time_dead,
        string memory _intro_rule,
        string memory _name01,string memory _name02
        ) public payable returns(address) {
        hoster_fee = _hoster_fee_thousandth;
        require(hoster_fee <= 30,"hoster_fee must <= 30");
        gameID = get_total_game_num() +1;
        gamename = _set_gamename;
        
        time_lock = _time_lock;
        time_dead = _time_dead;
        
        //設定主持人
        hoster = msg.sender;
        //創建遊戲
        new_game = new CREATE_GAME (
            owner,
            hoster,hoster_fee,
            referee,gamename,gameID,
            time_lock,time_dead,
            _intro_rule,
            _name01,_name02
            ).get_game_address();

        match_GAME[gameID] = new_game;
        return new_game;
    }

    function get_total_game_num () public view returns(uint256){
        return total_gameID;
    }

    function get_game_address (uint256 _gameID) public view returns(address){
        return match_GAME[_gameID];
    }

    function set_owner(address _new_owner) public onlyOwner {
        owner = _new_owner;
    }

    function get_owner() public view returns(address){
        return owner;
    }

    function set_referee(address _new_owner) public onlyOwner {
        owner = _new_owner;
    }

    function get_referee() public view returns(address){
        return referee;
    }

    function get_time() public view returns(uint256){
        return block.timestamp;
    }
}


contract CREATE_GAME{
    address owner;
    address hoster;
    uint256 hoster_fee;
    uint256 owner_fee = 15;

    address public referee;
    uint256 public game_result;
    
    uint256 public gameID;
    string public gamename;
    string public intro_rule;

    
    uint256 public time_deploy;
    uint256 public time_lock;
    uint256 public time_dead;


    uint256 position_01_total;
    uint256 position_02_total;
    string public position_Name_01;
    string public position_Name_02;
    mapping (address => uint256) position_01;
    mapping (address => uint256) position_02;
    mapping (address => uint256) position_01_unpay;
    mapping (address => uint256) position_02_unpay;
    uint256 public pool;
    uint256 pool_final;

    event Deposit(address indexed sender,uint256 position,uint256 value);
    event Withdraw(address indexed winer,uint256 value);
    event Reveal_Result(uint256 time,uint256 WhoIsWinner);

    constructor (address _owner,
        address _hoster,uint256 _hoster_fee,
        address _referee,
        string memory _gamename,uint256 _gameID,
        uint256 _time_lock,uint256 _time_dead,
        string memory _intro_rule,
        string memory _name01,string memory _name02
        ){
        //intro  //rule
        intro_rule = _intro_rule;

        //設定時間
        time_deploy = block.timestamp;
        //設定基本參數
            //帶入owner
        owner = _owner;
            //帶入主持人
        hoster = _hoster;
        hoster_fee = _hoster_fee;
            //帶入裁判
        referee = _referee;
        game_result = 0;//比賽結果預設為0

            //設定時間
        //time_start = _time_start;
        time_lock = _time_lock;
        time_dead = _time_dead;

            //比賽名稱及ID        
        gamename = _gamename;
        gameID = _gameID;

            //position NAME
        position_Name_01 = _name01;
        position_Name_02 = _name02;

    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Permission denied. onlyOwner");
        _;
    }

    modifier onlyReferee() {
        require(msg.sender == referee,"Permission denied. onlyReferee");
        _;
    }

    modifier onlyHoster() {
        require(msg.sender == hoster,"Permission denied. onlyHorster");
        _;
    }
    function get_game_address () public view returns (address) {
        return address(this);
    }

    function reveal_result (uint256 _result) public onlyReferee {
        require(block.timestamp > time_dead,"game not finish");
        pool_final = address(this).balance;
        game_result = _result;
        emit Reveal_Result(block.timestamp, game_result);
    }

    function deposit_to_P1 () public payable {
        require(block.timestamp < time_lock,"game is on,deposit function is locked.don`t send any $ into");
        require(msg.value > 0,"value can`t be zero");
        position_01[msg.sender] +=msg.value;
        position_01_total +=msg.value;
        pool = position_01_total + position_02_total;
        emit Deposit(msg.sender,1,msg.value);
    }

    function deposit_to_P2 () public payable {
        require(block.timestamp < time_lock,"game is on,deposit function is locked.don`t send any $ into");
        require(msg.value > 0,"value can`t be zero");
        position_02[msg.sender] +=msg.value;
        position_02_total +=msg.value;
        pool = position_01_total + position_02_total;
        emit Deposit(msg.sender,2,msg.value);
    }

    function check_deposit_P1 () public view returns(uint256){
        return position_01[msg.sender];
    }

    function check_deposit_P2 () public view returns(uint256){
        return position_02[msg.sender];
    }

    function check_TOTALamount_P1 () public view returns(uint256){
        return position_01_total;
    }

    function check_TOTALamount_P2 () public view returns(uint256){
        return position_02_total;
    }

    function time_now() public view returns(uint256){
        return block.timestamp;
    }

    function withdraw_Hoster () public onlyHoster {
        require(block.timestamp > time_lock,"game is on,not finish");
        require(game_result != 0,"referee hasn`t ref");

        address payable receiver = payable(hoster);
        uint256 value = address(this).balance/1000*hoster_fee;
        receiver.transfer(value);
        emit Withdraw(receiver,value);
    }

    function withdraw_Owner () public onlyOwner {
        require(block.timestamp > time_lock,"game is on,not finish");
        require(game_result != 0,"referee hasn`t ref");
        address payable receiver = payable(owner);
        uint256 value = address(this).balance/1000*owner_fee;
        receiver.transfer(value);
        emit Withdraw(receiver,value);
    }

    function withdraw_Owner_longtime () public onlyOwner {
        require(game_result != 0,"referee hasn`t ref");
        require(block.timestamp > time_lock + 2592000,"30days");
        address payable receiver = payable(owner);
        uint256 value = address(this).balance;
        receiver.transfer(value);
        emit Withdraw(receiver,value);
    }

    function withdraw_Winer () public {
        require(block.timestamp > time_lock,"game is on,not finish");
        require(game_result != 0,"referee hasn`t ref");
        
        uint256 value = 0;//value init

        if (game_result == 1){
            require(position_01[msg.sender]>0,"you are not the winer or already payed");
            value = pool_final * (1-(owner_fee + hoster_fee)/1000) * position_01[msg.sender] / position_01_total ;
            position_01[msg.sender] = 0; //清空
        }else if(game_result ==2){
            require(position_02[msg.sender]>0,"you are not the winer or already payed");
            value = pool_final * (1-(owner_fee + hoster_fee)/1000) * position_02[msg.sender] / position_02_total ;
            position_02[msg.sender] = 0; //清空
        }else if(game_result !=0){
            require(1<0,"none result");
        }

        address payable receiver = payable(msg.sender);
        receiver.transfer(value);
        emit Withdraw(receiver,value);
    }
}