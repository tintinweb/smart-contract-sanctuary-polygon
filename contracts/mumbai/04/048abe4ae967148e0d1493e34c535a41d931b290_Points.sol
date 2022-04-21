/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.5;

contract Points{
    enum contractState{
        informationFilling,//信息审核状态
        pointsDistribution,//积分状态
        waitConfirm,       //等待排名确认状态
        pointEnd           //积分结束状态
    }
    address private owner;
    bool private mutex;
    //积分管理条例
    mapping(uint256 => string) private pointsRegulation;
    uint private numberRegulation; //积分管理条例编号

    //用户结构体
    struct User{
        address account;
        string name;
        string phone;
        string idCard;
        uint256 score;
    }
    //等待验证用户列表
    User[] private userList;
    //验证成功的用户mapping
    mapping(address => User) private addrToUser;
    //用户身份映射
    mapping(bytes32 => address) public idCardToAddress;
    //用户积分链表
    mapping(address => uint256) private userPoints;
    mapping(address => address) private nextUser;
    uint256 public listSize;
    address constant Tail = address(1);

    //机构结构体
    struct Department{
        address account;
        string deptName;
        string phone;
        uint256 score;
    }
    //等待验证部门列表
    Department[] private deptList;
    //验证成功的机构mapping
    mapping(address => Department) private addrToDept;
    mapping(address => bool) private addrToIsUsed;
    //部门处理业务的数量
    mapping(address => uint256) private departmentCorrect;
    //部门处理业务争议的数量
    mapping(address => uint256) private departmentError;

    //积分编号
    uint256 pointNum = 1;
    //积分溯源 user->dept[]
    struct Point {
        uint256 number;             //积分编号
        int256 value;               //积分数量
        address dept;               //部门地址
        string deptName;            //部门名字
        uint256 regulationIndex;    //条例编号
        string deptReason;          //原因
    }
    mapping(address => Point[]) private trace;
    
    struct Dispute{
        uint256 number;             //积分编号
        address submitUser;         //申请人
        address disputeUser;        //争议人
        string  reason;             //原因
    }
    Dispute[] private disputeList;

    //事件
    event init(string[] regulation);
    event userEvent(string idCard, address userAddress, string name, string phone);
    event deptEvent(address deptAddress, string deptName, string phone);
    event verifyEvent(User[] userList, Department[] deptList);
    event mintPoint(string _idCard, int256 _value, uint256 _regulationIndex, string _reason);
    //溯源编号 部门名称 部门地址 积分值 条例编号 积分原因
    event userTrace(uint256 number, string deptName, address dept, int256 value, uint256 regulationIndex, string deptReason);
    event topk(User[] topList);

    //初始化合约
    constructor(string[] memory _regulation) {
        mutex = true;
        owner = msg.sender;
        nextUser[Tail] = Tail; //初始化表头
        listSize = 0;
        numberRegulation = 0;
        for(uint256 i = 0; i < _regulation.length; ++i) {
            pointsRegulation[numberRegulation]=_regulation[i];
            numberRegulation++;
        }
        emit init(_regulation);
    }

    function getOwner() public view virtual returns (address){
        return owner;
    }

    //用户提交身份信息 放到userList 等待验证
    function submitByUser(string memory _idCard, address _address, string memory _name, string memory _phone)public returns (bool){
        if(mutex == false)
            return false;
        User memory user;
        user.account = _address;
        user.name = _name;
        user.phone =_phone;
        user.idCard = _idCard;
        user.score = 0;
        userList.push(user);
        emit userEvent(_idCard, _address, _name, _phone);
        return true;
    }
    
    //机构提交身份信息 放到deptList 等待验证
    function submitByDept(address _address, string memory _deptName, string memory _phone)public returns (bool){
        if(mutex == false)
            return false;
        Department memory dept = Department(_address,_deptName,_phone,0);
        dept.account = _address;
        dept.deptName = _deptName;
        dept.phone= _phone;
        dept.score = 0;
        deptList.push(dept);
        emit deptEvent(_address, _deptName, _phone);
        return true;
    }
    
    //验证信息(积分管理办公室)
    function verifyInfomation() public {
        require(msg.sender == owner);
        mutex = false;
        //处理用户信息
        for(uint256 i = 0; i < userList.length; i++){
            addrToUser[userList[i].account] = userList[i];
            idCardToAddress[keccak256(abi.encodePacked(userList[i].idCard))] = userList[i].account;
            addUser(userList[i].account, 0);
        }

        //处理机构信息
        for(uint256 i = 0; i < deptList.length; i++){
            addrToDept[deptList[i].account] = deptList[i];
            departmentCorrect[deptList[i].account] = 0;
            departmentError[deptList[i].account] = 0;
            addrToIsUsed[deptList[i].account] = true;
        }
        mutex = true;
        emit verifyEvent(userList, deptList);
        delete userList;
        delete deptList;
    }

    //通过身份证获取地址
    function getAddressByIdcard(string memory _idCard)
    public 
    view
    virtual 
    returns (address){
        return idCardToAddress[keccak256(abi.encodePacked(_idCard))];
    }

    //获取积分(address)
    function getPointsByaddr(address _address)
    public 
    view 
    virtual 
    returns (uint256){
        return userPoints[_address];
    }
    
    //获取积分(IdCard)
    function getPointsById(string memory _idCard)
    public 
    view
    virtual 
    returns (uint256){
        //require(msg.sender == _owner);
        address _addr = getAddressByIdcard(_idCard);
        return userPoints[_addr];
    }

    //给某个用户发放积分(机构)
    function mintToUser(int256 _value, string memory _idCard, uint256 _regulationIndex,string memory _reason) public virtual returns (bool){
        require(addrToIsUsed[msg.sender] == true);
        address _userAddr = getAddressByIdcard(_idCard);
        require(_userAddr != address(0x0));
        require(_value > 0);
        _increasePoint(_userAddr, uint256(_value));
        
        //溯源积分
        Point memory _point;
        _point.dept = msg.sender;
        _point.value = _value;
        _point.deptName = addrToDept[msg.sender].deptName;
        _point.regulationIndex = _regulationIndex;
        _point.deptReason = _reason;
        _point.number = pointNum;
        pointNum++;
        trace[_userAddr].push(_point);

        departmentCorrect[msg.sender]++;
        emit mintPoint(_idCard, _value, _regulationIndex, _reason);
        emit userTrace(pointNum, addrToDept[msg.sender].deptName, msg.sender, _value, _regulationIndex, _reason);
        return true;
    }

    //获取某个用户的积分溯源
    function getPointTrace(string memory _idCard)
    public 
    view
    returns(Point[] memory){
        address _userAddr = getAddressByIdcard(_idCard);
        require(_userAddr != address(0x0));
        return trace[_userAddr];
    }

    //争议提交(用户提交)
    function disputeSubmit(address _account, uint256 _number, string memory _reason)
    public 
    virtual 
    returns(bool){
        Dispute memory dispute;
        dispute.number = _number;
        dispute.submitUser = msg.sender;
        dispute.disputeUser = _account;
        dispute.reason = _reason;
        disputeList.push(dispute);
        return true;
    }
    
    //获取积分争议(积分管理办公室)
    function getDispute()
    public 
    virtual 
    returns(Dispute[] memory){
        require(msg.sender == owner);
        return disputeList;
    }

    //撤销积分(积分管理办公室)
    function revokeUserPoints(address _userAccount, uint256 _number, string memory _reason)
    public 
    virtual 
    returns(bool){
        require(msg.sender == owner);
        //找到这笔积分溯源
        Point memory _point;
        for(uint256 i = 0; i < trace[_userAccount].length; i++){
            if(trace[_userAccount][i].number == _number){
                _point = trace[_userAccount][i];
            }
        }
        _reducePoint(_userAccount, uint256(_point.value));

        _point.value = -_point.value;
        _point.number = pointNum;
        _point.deptReason = _reason;
        trace[_userAccount].push(_point);
        pointNum++;
        return true;
    }

    //用于验证该值在左右地址之间
    function _verifyIndex(address _prev, uint256 _newPoint, address _next)
    internal
    view
    returns(bool)
    {
        return (_prev == Tail || userPoints[_prev] >= _newPoint) &&
            (_next == Tail || _newPoint > userPoints[_next]);
    }

    //查找新值应该插入在哪一个地址后面
    function _findIndex(uint256 _newPoint) 
    internal 
    view 
    returns(address) {
        address candidate = Tail;
        while(true) {
            if(_verifyIndex(candidate, _newPoint, nextUser[candidate]))
                return candidate;
            candidate = nextUser[candidate];
        }
    }

    //插入
    function addUser(address user, uint256 point) internal {
        require(nextUser[user] == address(0));
        address index = _findIndex(point);
        userPoints[user] = point;
        nextUser[user] = nextUser[index];
        nextUser[index] = user;
        listSize++;
    }

    //检查前一个用户并找到前一个用户
    function _isPrevUser(address user, address prevUser)
    internal 
    view 
    returns(bool) {
        return nextUser[prevUser] == user;
    }

    //检查前一个用户并找到前一个用户
    function _findPrevUser(address user)
    internal 
    view 
    returns(address) {
        address currentAddress = Tail;
        while(nextUser[currentAddress] != Tail) {
            if(_isPrevUser(user, currentAddress))
                return currentAddress;
            currentAddress = nextUser[currentAddress];
        }
        return address(0);
    }

    //删除User函数
    function removeUser(address user) internal {
        require(nextUser[user] != address(0));
        address prevUser = _findPrevUser(user);
        nextUser[prevUser] = nextUser[user];
        nextUser[user] = address(0);
        userPoints[user] = 0;
        //ToDo : Idcard也要删 ?
        listSize--;
    }

    //增加积分
    function _increasePoint(address user, uint256 point) internal{
        updatePoint(user, userPoints[user] + point);
    }

    //扣除积分
    function _reducePoint(address user, uint256 point) internal{
        updatePoint(user, userPoints[user] - point);
    }

    //更新积分
    function updatePoint(address user, uint256 newPoint) internal{
        require(nextUser[user] != address(0));
        address prevUser = _findPrevUser(user);
        address nextUser = nextUser[user];
        if(_verifyIndex(prevUser, newPoint, nextUser)){
            userPoints[user] = newPoint;
        } else {
            removeUser(user);
            addUser(user, newPoint);
        }
    }

    //返回前K个top
    function getTop(uint256 k) public returns(address[] memory) {
        require(k <= listSize);
        address[] memory userLists = new address[](k);
        address currentAddress = nextUser[Tail];
        for(uint256 i = 0; i < k; ++i) {
            userLists[i] = currentAddress;
            currentAddress = nextUser[currentAddress];
        }
        User[] memory eventRes = new User[](k);
        for(uint256 i = 0; i < k; ++i) {
            eventRes[i]=addrToUser[userLists[i]];
            eventRes[i].score= userPoints[eventRes[i].account];
        }
        emit topk(eventRes);
        return userLists;
    }
}