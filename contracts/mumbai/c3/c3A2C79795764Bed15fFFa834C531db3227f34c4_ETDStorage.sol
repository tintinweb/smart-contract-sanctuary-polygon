// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import './IStorage.sol';
 


contract ETDStorage is  Initializable, OwnableUpgradeable,AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    //address payable public etdOwner;
    IERC20Burnable public StorageToken; // ƽ̨��
    IStorageNFT public StorageNFT; // ƽ̨NFT
    // details about the uniswap position
    struct File {
        string   owner;   //  //wallet address
        uint128  size;        // file size, unit: bytes
        uint256  createTime;  //file create time, unix time: seconds
        uint256  deadline;   // max saving time in contract,  unix time: seconds
        string   uri;        // NFT uri
        string   uuid;       // backend need it
        bool     status;     // true : file is active and can be visited; 
    }

   
    /// @dev The token ID file data
    mapping(string => File) private _files;
    mapping(string => string) public  fileOwner;


    //������ؼ۸񣬲���etd ��ۣ���С��λ�� wei/byte. ����չʾ�� �۱�/GBÿ�� �� ����� Ԫ/GBÿ�¡�
    // ��ΪĿǰ��ûԤ�Ի������۸�仯ʱ������etd�۸�仯������Ҫϵͳ���������⼸���۸�
    uint256 public bandwidthPrice;    //���ش����۸� ÿ�ֽڶ��� etd,��λ: wei. ��Ϊʵ���ǰ��� ���ұ��ۣ�ת��etd ����etd�۸񲨶����������Ҳ��������
   
    uint256 public perSegmentPrice;   // ����۸�wei.�ļ�����64MB �зֳɿ飬ÿ�������зֳ�80��Ƭ��ֻ��Ҫ��ȡ29��Ƭ�����ɻָ��ÿ����ݣ���ЩƬ�ֲ�ʽ�洢�ڲ�ͬ�ڵ㣻
                                      //��С��64MB���ļ������� 1M ���ļ����������࣬����û�г���10G��ѿռ䣬�����п��ܳ������ֿ�����Ҳ��Ʒѣ�  
    uint128  public  freeBandwidth;       //ÿ���û� ÿ�����������������λ�ֽ�

    //==================
    uint public dailyNewFreeStorLimit; //ÿ�������洢�������ֽ�����  3G=30,000,000,000
    uint public dailyNewFreeFileLimit; //ÿ����������ļ���
    uint public dailyNewStorPrice; //ÿ�������洢�������ã�Mb/Ether��0.0001  1000000000000000
    uint public dailyNewFilePrice; //ÿ�����������ļ��շ�  0.0001 1000000000000000

    uint public freeStorage;       //ÿ���û� ��ѿռ䣬 ��λ �ֽڣ�������� 10G =10*1000*1000*1000 �ֽڣ���ʮ���ƣ�
    uint public freeFileCount;     //ÿ���û� ����ļ���
    uint public storagePrice;      //�洢�۸�ÿ����ÿG ����etd ,��λ: wei. 1000000000000000
    uint public perFilePrice;       //�����ļ��շ� 0.0001 1000000000000000


     
    mapping(string => uint256) public userBalance; //�û�Ԥ֧����etd ��ÿ���£� ��̨�۷Ѻ���Ҫ�޸����ֵ;�û�������ʱ��Ҫ�ʼ�֪ͨ�û���  
                                                    //�û����ϴ��ļ�ʱ����̨Ҫ��������� �Ƿ��㹻֧������ļ��� �洢���á�
    //  mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;
    
    //ͳ��ÿ���û���ʹ�ÿռ�, �û�ֻ������һ��Ǯ����ַ���������ַ�䶯����Ӧ����Ϣ����仯��
    mapping(string => uint256)  userTotalStorage;

    //��¼ÿ��ķ��ñ�׼
    struct FeeRecord {
        uint  bandwidthPrice;    //���ش����۸� ÿ�ֽڶ��� etd,��λ: wei. ��Ϊʵ���ǰ��� ���ұ��ۣ�ת��etd ����etd�۸񲨶����������Ҳ��������
        uint  freeBandwidth;
        uint  dailyNewFreeStorLimit; //ÿ�������洢�������ֽ�����  3G=30,000,000,000
        uint  dailyNewFreeFileLimit; //ÿ����������ļ���
        uint  dailyNewStorPrice; //ÿ�������洢�������ã�Mb/Ether��0.0001
        uint  dailyNewFilePrice; //ÿ�����������ļ��շ�  0.0001 

        uint  freeStorage;       //ÿ���û� ��ѿռ䣬 ��λ �ֽڣ�������� 10G =10*1000*1000*1000 �ֽڣ���ʮ���ƣ�
        uint  freeFileCount;     //ÿ���û� ����ļ���
        uint  storagePrice;      //�洢�۸�ÿ����ÿG ����etd ,��λ: wei.
        uint  perFilePrice;       //�����ļ��շ� 0.0001
    }

    //ÿ��ķ��ñ�׼��¼
    mapping(uint16 => mapping(uint8 =>mapping(uint8 => FeeRecord))) public feeRecordList;

   
    mapping(address => mapping(uint => mapping(uint => uint256))) public minerPayFlag; //ÿ���¸��󹤽���һ�Σ������½����ˣ��������ٸ������
    mapping(string => mapping(uint => mapping(uint => uint256))) public userChargeFlag; //ÿ���¿�һ���û����ã������½����ˣ������ٿ۷�

    mapping(string => mapping(uint => mapping(uint => uint256))) public userCharge; //ÿ�½ɷѽ��
    
    //ÿ��ʹ�����
    struct DailyDetail {
        uint256 day; //���ڣ����µĵڼ���
        uint256 totalSize; //���ֽ���
        uint256 dailySummary; //���ջ���
        uint256 dailycount;   //�����ļ�������
        uint256 totalCount;  //���ļ���
        uint256 totalBandwidth; //���յĴ���,�����������£�ֻ��ͳ�Ʒ���ʱд����ֶΣ�
        uint256 charge;   //���շ���
    }

    //����ÿ��Ĵ洢�ֽ��� (address[year][month][day])
    mapping (string => mapping(uint16 => mapping(uint8 =>mapping(uint8 => DailyDetail)))) public storageDailyRec;

    //ÿ����Ŀ�Ĵ�������
    struct ProjectDailyBandwidth{
        string projectId;
        uint256 day; //���ڣ����µĵڼ���
        uint256 dailyBandwidth; //���յĴ���
    }
    //����ÿ��������ֽ��� (address[year][month][day])
    mapping (string => mapping(uint16 => mapping(uint8 =>mapping(uint8 => ProjectDailyBandwidth[])))) public bandwidthDailyRec;


    //�û���Ӧ��ַ
    mapping (string => address) public userWallet;

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    string public baseURI;
    string public contractURI;

    mapping(string => mapping(string => uint256)) public userPays; //�û����ҽɷѼ�¼

    struct userPay{
        string   userId;
        string   payOrder;
        uint amount;
    }
    
    event PrePay(address sender,string user,string payOrder, uint256 value);
    event ReFund(string user, uint256 value);
    event MonthlyBalance(string user, uint256 billTime, uint256 fee);
    //���Ѹ���
    event PayMiner(address miner,  uint256 billTime, uint256 fee);
    
    //�û������¼
    event UserPay(string miner,  uint year, uint month, uint fee);
    event SaveFile(string addr, string uuid);
    event RemoveFile(string addr, string uuid);

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, 'Transaction too old');
        _;
    }

    //ͳ��ÿ���û�����ʹ�ô���, �ŵ����£��ɺ�̨ȥͳ��


    /// @custom:oz-upgrades-unsafe-allow constructor
    //constructor() {
         //initialize();
         //_disableInitializers();
         
    //}

    function initialize() initializer public {
        __Ownable_init();
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        bandwidthPrice = 2000000;
        freeBandwidth = 5000000000;
        dailyNewFreeStorLimit = 1000000000;
        dailyNewFreeFileLimit = 100; 
        dailyNewStorPrice = 1000000;
        dailyNewFilePrice =  1000000000000;
        freeStorage = 5000000000;
        freeFileCount =  1000;
        storagePrice =  1000000;
        perFilePrice = 1000000000000;
        //etdOwner = payable(msg.sender);
    }


    //
    function files(string memory _uuid)
        external
        view
        returns (          
            string   memory owner,
            uint128  size,
            uint256  createTime,
            uint256  deadline,
            string   memory uri, 
            string   memory uuid,
            bool     status
        )
    {
        File memory file = _files[_uuid];

        return (
           
            file.owner,
            file.size,
            file.createTime,
            file.deadline,
            file.uri,
            file.uuid,
            file.status
        );
    }

    //����ÿ������/ɾ���洢
    //mapping (address => mapping(uint16 => mapping(uint8 =>mapping(uint8 => DailyUserFile)))) public userFileRec;

    // ����˻����
    //����Ҫ����Щ������飬�Ƿ�������
    function saveFile(File calldata file) public 
        checkDeadline(file.deadline)
        onlyOwner        
    {
        require(file.size > 0, 'Invalid file size');
        require(bytes(fileOwner[file.uuid]).length == 0, 'user file uuid has  been used');        

        _files[file.uuid] = File({
            owner: file.owner,
            size: file.size,
            createTime: file.createTime,
            deadline: file.deadline,
            uri: file.uri,
            uuid: file.uuid,
            status: file.status
        });
        userTotalStorage[file.owner] = userTotalStorage[file.owner] + file.size; 

        (uint year, uint month,uint day) = _daysToDate(block.timestamp);

        DailyDetail memory detail = storageDailyRec[file.owner][uint16(year)][uint8(month)][uint8(day)];

        detail.day = day;
        detail.totalSize = userTotalStorage[file.owner] ;
        detail.dailySummary = detail.dailySummary + file.size;
        detail.dailycount = detail.dailycount + 1;
        detail.totalCount = detail.totalCount + 1;

        storageDailyRec[file.owner][uint16(year)][uint8(month)][uint8(day)] = detail; 

        fileOwner[file.uuid]= file.owner; 

        emit SaveFile(file.owner, file.uuid);
	    
    }

    function batchSaveFile(File[] calldata fileList) external onlyOwner{
        for(uint i = 0; i < fileList.length; i++) {
            saveFile(fileList[i]);
        }
    }



    function removeFile(string memory uuid) public onlyOwner {
        //require(msg.sender == ownerOf(tokenId),"Only the owner of this Token could Burn It!");
        File storage file = _files[uuid];
        require(file.size != 0, 'Invalid token ID');
	    userTotalStorage[file.owner] -= file.size; 
       

        (uint year, uint month,uint day) = _daysToDate(block.timestamp);
        DailyDetail memory detail = storageDailyRec[file.owner][uint16(year)][uint8(month)][uint8(day)];
        detail.totalSize = userTotalStorage[file.owner] ;
        detail.totalCount = detail.totalCount - 1;

        storageDailyRec[file.owner][uint16(year)][uint8(month)][uint8(day)] = detail; 

        delete fileOwner[file.uuid];        
	    emit RemoveFile(file.owner, file.uuid);
        delete _files[uuid];

        // //_burn(tokenId);

    }

    function batchRemoveFile(string[] memory uuids) public onlyOwner
    {
        for(uint i = 0; i < uuids.length; i++) {
            removeFile(uuids[i]);
        }

    }

    //save user's bandwidth 
    function saveUserBandwidth(string memory userId, uint year, uint month,uint day,ProjectDailyBandwidth[] calldata bandwidthArray) public onlyOwner{
        uint256 len = bandwidthArray.length;
        
        for(uint i = 0; i < len; i++) {
            require(day == bandwidthArray[i].day, 'Invalid day');
            //�����ظ�����
            require(checkUserBandwidthStatus(bandwidthDailyRec[userId][uint16(year)][uint8(month)][uint8(day)],bandwidthArray[i].projectId), 'Repeated projectId');
            bandwidthDailyRec[userId][uint16(year)][uint8(month)][uint8(day)].push(
                ProjectDailyBandwidth(
                    bandwidthArray[i].projectId,
                    bandwidthArray[i].day,
                    bandwidthArray[i].dailyBandwidth
                    )
                );
        }
    }

    function checkUserBandwidthStatus(ProjectDailyBandwidth[] memory pdb,string memory projectId)public pure returns(bool) {
        for(uint i = 0; i < pdb.length; i++){
            if(isEqual(projectId,pdb[i].projectId)){
                return false;
            }
        }
        return true;
    }

    function isEqual(string memory a, string memory b) public pure returns (bool) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        // ������Ȳ��ȣ�ֱ�ӷ���
        if (aa.length != bb.length) return false;
        // ��λ�Ƚ�
        for(uint i = 0; i < aa.length; i ++) {
            if(aa[i] != bb[i]) return false;
        }
 
        return true;
    }


    function getUserBandwidthByDay(string memory userId, uint year, uint month,uint day) public view returns(ProjectDailyBandwidth[] memory ) {
        return bandwidthDailyRec[userId][uint16(year)][uint8(month)][uint8(day)];
    }
    
    struct userBandwidth{
        string userId;
        ProjectDailyBandwidth[]   bandwidthArry;
    }

    //���������û��Ĵ���
    function batchSaveUserYesterdayBandwidth(userBandwidth[] calldata usersBandwidthArray) public onlyOwner{
        //���������
        (uint year, uint month,uint day) = _daysToDate(block.timestamp-86400); 
        for(uint i = 0; i < usersBandwidthArray.length; i++) {
           saveUserBandwidth(usersBandwidthArray[i].userId,year,month,day,usersBandwidthArray[i].bandwidthArry);
        }
    }


    //
    function setStatus(string memory uuid, bool status) public onlyOwner {
        File storage file = _files[uuid]; //how to check  the tokenid is invalid ?
        require(file.size != 0, 'Invalid token ID');
        file.status = status;
    }

    //
    function setBandwidthPrice(uint160 _price) public onlyOwner {
         bandwidthPrice = _price;
    }



    //free bandwidth, unit: bytes
    function setFreeBandwidth(uint128 _freeBandwidth) public onlyOwner {
         freeBandwidth =_freeBandwidth;
    }

    //1. to do: how to charge or pre-pay ; 2.�ļ����ڣ��������ѣ�
    //mapping(address => uint256) public userBalance   �����Ե���Ԥ֧����Ҳ�������ļ�����ʱת�ˡ����û������洢���������ʣ�£�Ҫ֧��withdraw
   
   //
    function getUserBalance(string memory userId) external view returns (uint256)  {
      return userBalance[userId];
   }
   //
   function getUserTotalStorage(string memory userId) external view returns (uint256)  {
      return userTotalStorage[userId];
   }

   //����Ӧ���û���ֵ
   function prePay(string memory userId,string memory payOrder,uint _amount)
        public
        {
            require(_amount > 0, 'Invalid value');
            require(userPays[userId][payOrder] == 0, 'Order has been dealed');         
            uint m = StorageToken.balanceOf(msg.sender);
            //emit CheckAmount(msg.sender,m);
            require(m >= _amount ,"transfer amount exceeds user balance");

            userPays[userId][payOrder] = _amount;
            
            //recipient �տ��˻�����Լ?��
            StorageToken.transferFrom(msg.sender,address(this),_amount);
            //emit TransferToken(msg.sender,address(this),_amount);

            userBalance[userId] += _amount;
            emit PrePay(msg.sender, userId, payOrder,_amount);
     
        }
   

    //event UserPay(string userId, string payOrder,uint amount);
    function batchUserPay(userPay[] memory userPayArray) external{
         for(uint i = 0; i < userPayArray.length; i++) {
           prePay(userPayArray[i].userId,userPayArray[i].payOrder,userPayArray[i].amount);
           //emit UserPay
        }
    }
    //ETD is similar to ETH  and use the same transfer function.
//    function reFund(uint256 value)
//         external
//         payable
//         {   
//             uint256  balance = userBalance[msg.sender];
//              require( balance > value, "balance is not enough.");
//             // //������������һ���µĴ洢����
//             // require( 
//             //     (balance - value) > ( userTotalStorage[msg.sender]  - freeStorage)*storagePrice ,
//             //     "user balance is not enough!"
//             // );
//             userBalance[msg.sender] = balance - value;
//             payable(msg.sender).transfer(value);
//             emit ReFund(msg.sender,  value);
//         }



    //�û��ļ� ����û�����ѣ� ���˼��죬�����ѡ������������δ�����TBD

    //TBD: �洢��ע�� Ǯ����ַ �ȡ�
    //��̨���ڸ��󹤽���ETD

    function payMiner(address miner,  uint256 billTime, uint256 fee) external payable onlyOwner{   
            uint256  balance = address(this).balance;
             require( balance >= fee, "contract balance is not enough!");
            // ����һ������״̬����¼������֧���󹤷���
            (uint year, uint month,) = _daysToDate(billTime);
            require( minerPayFlag[miner][year][month] == 0, "miner has been payed!");
            minerPayFlag[miner][year][month] = fee;

            payable(miner).transfer(fee);
            emit PayMiner( miner,  billTime,  fee);
    }
    // returns fee > 0, this shows the miner has been payed in the month.
    function getMinerPayFlag(address miner, uint256 billTime) view public returns (uint256 fee){
            (uint year, uint month,) = _daysToDate(billTime);
            fee = minerPayFlag[miner][year][month] ;

    }

    //�½��㺯��, ��ÿ���˵������һ�죬�ɺ�̨����������API
    //��̨�Ʒ� ��Ҫ��ÿ���˻����ӱ�־��˵�����ڷ����ѽ��㣬�����ظ��շѡ�
    //��Ҫ������û� ���ļ���С��

    // function chargeUser(address user, uint256 billTime, uint256 fee) external onlyOwner{
    //     (uint year, uint month,) = _daysToDate(billTime);
    //     require( userChargeFlag[user][year][month] == 0, "user has been charged!");
    //     uint256  balance = userBalance[user];
    //     require(balance >= fee, "user balance is not enough!");
    //     userBalance[user] = balance - fee ;

    //     emit MonthlyBalance( user,  billTime,  fee);

    // }

    //ÿ���������û�����,�ɺ�ִ̨�У�������
    //function checkUser () {
    //}



    //����ÿ��ļ۸��¼
    function updateFeeRecord(uint256 timestamp) public onlyOwner {
        (uint year, uint month,uint day) = _daysToDate(timestamp);
        if (feeRecordList[uint16(year)][uint8(month)][uint8(day)].storagePrice == 0){
            FeeRecord storage _feeRecord = feeRecordList[uint16(year)][uint8(month)][uint8(day)];
            _feeRecord.bandwidthPrice = bandwidthPrice;
            _feeRecord.freeBandwidth = freeBandwidth;
            _feeRecord.dailyNewFreeStorLimit = dailyNewFreeStorLimit;
            _feeRecord.dailyNewFreeFileLimit = dailyNewFreeFileLimit;
            _feeRecord.dailyNewStorPrice = dailyNewStorPrice;
            _feeRecord.dailyNewFilePrice = dailyNewFilePrice;
            _feeRecord.freeStorage = freeStorage;
            _feeRecord.freeFileCount = freeFileCount;
            _feeRecord.storagePrice = storagePrice;
            _feeRecord.perFilePrice = perFilePrice;
        }
    }

    //updateTodayFeeRecord
    function updateTodayFeeRecord() public onlyOwner {
        updateFeeRecord(block.timestamp);
    }

    //�����û��洢ʹ�����ݣ�ʱ����������ڵ����ݣ�0���ִ̨�У������⵽û����������ݣ���Ҫִ�����������
    function updateUserDayDetail(string memory user_id,uint256 timestamp) public onlyOwner{
        uint256 oneDay = 86400;
        //timestamp = timestamp - oneDay; 
        (uint year, uint month,uint day) = _daysToDate(timestamp);
        
        DailyDetail storage detail = storageDailyRec[user_id][uint16(year)][uint8(month)][uint8(day)];
        if (detail.day == 0){
            uint256 yesterday = timestamp - oneDay; 
            detail.day = day;

            (uint yearYesterday, uint monthYesterday,uint dayYesterday) = _daysToDate(yesterday);
            DailyDetail memory detailYesterday = storageDailyRec[user_id][uint16(yearYesterday)][uint8(monthYesterday)][uint8(dayYesterday)];
            detail.totalSize = detailYesterday.totalSize;
            detail.totalCount = detailYesterday.totalCount;
        }
    }


    //���������û�
    function batchUpdateUserDayDetail(string[] memory users,uint256 timestamp) public onlyOwner{
        for (uint i = 0; i < users.length; i++){
            updateUserDayDetail(users[i],timestamp);
        }
    }
    
    //��ȡ�û�ÿ����ʷ����
    function getUserMonthDetail(string memory userId,uint year,uint month ) public view returns (DailyDetail[32] memory, uint total) {
        DailyDetail[32] memory list;
        total = 0 ;
        uint totalBW = 0;

        for(uint8 i = 1; i < 32; i++) {           
           DailyDetail memory detail = storageDailyRec[userId][uint16(year)][uint8(month)][i];
           uint charge = 0;
           FeeRecord memory _feeRecord = feeRecordList[uint16(year)][uint8(month)][uint8(detail.day)];
           if (detail.day > 0 ){               
               
               if(detail.dailycount > dailyNewFreeFileLimit){
                    charge = charge + (detail.dailycount - _feeRecord.dailyNewFreeFileLimit)*_feeRecord.dailyNewFilePrice;
                }
                if(detail.dailySummary > dailyNewFreeStorLimit){
                    charge = charge + (detail.dailySummary - _feeRecord.dailyNewFreeStorLimit)*_feeRecord.dailyNewStorPrice;
                }
                if(detail.totalSize > freeStorage){
                    charge = charge + (detail.totalSize - _feeRecord.freeStorage)*_feeRecord.storagePrice;
                }
                if(detail.totalCount > freeFileCount){
                    charge = charge + (detail.totalCount - _feeRecord.freeFileCount)*_feeRecord.perFilePrice;
                }

           }

            //��������۸�
            ProjectDailyBandwidth[] memory bw =  bandwidthDailyRec[userId][uint16(year)][uint8(month)][i];
            uint yesterdayTotalBW;
            yesterdayTotalBW = totalBW;
            uint todayTotalBW = 0;
            for (uint j = 0; j < bw.length; j++){
                totalBW = totalBW + bw[j].dailyBandwidth;
                todayTotalBW = todayTotalBW + bw[j].dailyBandwidth;
            }

            if(totalBW > _feeRecord.freeBandwidth){
                //�������������Ѿ����꣬����ֻ��ȡ���ӵ���������
                if(yesterdayTotalBW > _feeRecord.freeBandwidth){
                    charge = charge + todayTotalBW*_feeRecord.bandwidthPrice;
                }else{
                    charge = charge + (totalBW - _feeRecord.freeBandwidth)*_feeRecord.bandwidthPrice;
                }
                
            }

           detail.totalBandwidth = totalBW;
           detail.charge = charge;
           list[i] = (detail);

           total = total + charge;
           
        }
        return (list,total);
    }




    function getUserTodayDetail(string memory user) public view returns(DailyDetail memory){
        (uint year, uint month,uint day) = _daysToDate(block.timestamp);
        DailyDetail memory detail = storageDailyRec[user][uint16(year)][uint8(month)][uint8(day)];
        if (detail.day == 0){
            uint256 oneDay = 86400;
            uint256 yesterday = block.timestamp - oneDay; 
            (uint yearYesterday, uint monthYesterday,uint dayYesterday) = _daysToDate(yesterday);
            DailyDetail memory detailYesterday = storageDailyRec[user][uint16(yearYesterday)][uint8(monthYesterday)][uint8(dayYesterday)];
            //return detailYesterday;
            detail = detailYesterday;
        }

        uint charge = 0;
        uint totalBW = 0;
        if(detail.dailycount > dailyNewFreeFileLimit){
            charge = charge + (detail.dailycount - dailyNewFreeFileLimit)*dailyNewFilePrice;
        }
        if(detail.dailySummary > dailyNewFreeStorLimit){
            charge = charge + (detail.dailySummary - dailyNewFreeStorLimit)*dailyNewStorPrice;
        }
        if(detail.totalSize > freeStorage){
            charge = charge + (detail.totalSize - freeStorage)*storagePrice;
        }
        if(detail.totalCount > freeFileCount){
            charge = charge + (detail.totalCount - freeFileCount)*perFilePrice;
        }
       

        //��������

        ProjectDailyBandwidth[] memory bw =  bandwidthDailyRec[user][uint16(year)][uint8(month)][uint8(day)];
        
        uint yesterdayTotalBW;
        yesterdayTotalBW = totalBW;
        uint todayTotalBW = 0;
        for (uint j = 0; j < bw.length; j++){
            totalBW = totalBW + bw[j].dailyBandwidth;
            todayTotalBW = todayTotalBW + bw[j].dailyBandwidth;
        }

        if(totalBW > freeBandwidth){
            //�������������Ѿ����꣬����ֻ��ȡ���ӵ���������
            if(yesterdayTotalBW > freeBandwidth){
                charge = charge + todayTotalBW*bandwidthPrice;
            }else{
                charge = charge + (totalBW - freeBandwidth)*bandwidthPrice;
            }
            
        }

        detail.totalBandwidth = totalBW;
 
        detail.charge = charge;
        
        return detail;

    }

   
    function _daysToDate(uint blocktimes) internal pure returns (uint year, uint month, uint day) {
        uint SECONDS_PER_DAY= 24*60*60;
        int __days = int(blocktimes/SECONDS_PER_DAY);
        int  OFFSET19700101 = 2440588;
 
        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
 
        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function  getDate(uint blocktimes) pure public  returns(uint year, uint month, uint day) {
        (year, month, day) = _daysToDate( blocktimes);
    
    }

    function setDailyNewFreeStorLimit(uint fileBytes) external onlyOwner{
      dailyNewFreeStorLimit = fileBytes;
    }

    function setDailyNewFreeFileLimit(uint count) external onlyOwner{
      dailyNewFreeFileLimit  = count;
    }

    function setDailyNewStorPrice(uint price) external onlyOwner{
      dailyNewStorPrice  = price;
    }

    function setDailyNewFilePrice(uint price) external onlyOwner{
      dailyNewFilePrice  = price;
    }

    //
    function setStoragePrice(uint price) public onlyOwner {
        storagePrice = price;
    }

    function setPerFilePrie(uint price) public onlyOwner {
        perFilePrice = price;
    }

    function setFreeFileCount(uint count) public onlyOwner {
        freeFileCount = count;
    }

    //free storage, unit: bytes
    function setFreeStorage(uint128 _freeStorage) public onlyOwner {
         freeStorage =_freeStorage;
    }


    //ÿ�¼���һ���շѣ�Ҫ��ȷ�����������������ٺ�̨�ȼ����շѣ�����շѲ�����
    function userBill(string memory user, uint year,uint month) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        (, uint charge) = getUserMonthDetail(user,year,month);
        //��ȥ��ǰ�ɷѽ��,�鿴����Ƿ����
        charge = charge - userCharge[user][year][month];
        if (charge > 0) {
            require( userChargeFlag[user][year][month] == 0, "user has been charged!");
            uint256  balance = userBalance[user];
            require(balance >= charge, "user balance is not enough!");
            userBalance[user] = balance - charge ;
            //������ǵ��£�����Ϊ 1�����¿��ܶ�νɷѣ�
            (, uint _month,) = _daysToDate(block.timestamp);
            if(_month != month){
                userChargeFlag[user][year][month] = 1;
            }
            //���������νɷѣ���¼��ǰ�Ľɷѽ��
            userCharge[user][year][month] = userCharge[user][year][month] + charge;
            emit UserPay(user, year, month, charge);
        }
    }

    //��ʱ��ɹ�ȥ�ķ���
    // function userBillx() public onlyOwner{
    //     for (uint j = 6; j > 0; j--){
    //         (uint _year, uint _month,) = _daysToDate(block.timestamp-(day+j)*24*60*60);
    //         if (userChargeFlag[user][_year][_month] == 0){
    //              (, _charge) = getUserMonthDetail(user,_year,_month);
    //          }
    //     }
    // }



    function getUserAvailableBalance(string memory user) public view returns(int){
        //�����6����û���壿
        (uint year, uint month,uint day) = _daysToDate(block.timestamp);
        
        uint _charge = 0;
        uint dayx = 0;
        uint t = block.timestamp-(day)*24*60*60;
        for (uint j = 1; j < 7; j++){
            (uint _year, uint _month,uint _day) = _daysToDate(t-dayx*24*60*60);
            dayx=_day;
            t = t-dayx*24*60*60;
            if (userChargeFlag[user][_year][_month] == 0){
                 (, _charge) = getUserMonthDetail(user,_year,_month);
             }
        }

        //�û��˻����-�����ܷ���=��Ч���
    
        uint charge;
        (, charge) = getUserMonthDetail(user,year,month);
        if (userBalance[user] >= charge + _charge) {
            return int(userBalance[user] - charge - _charge);
        }else{
            return int(charge + _charge - userBalance[user])* -1 ;
        }
        //return int(charge);
    }

    //�Ӻ�ԼתETD
    function transferTo(address payable _to, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        _to.transfer(_amount);
    }

    //�Ӻ�Լתtoken
    function transferTokenTo(address _to, uint256 _amount) public onlyOwner {
        StorageToken.transfer(_to, _amount);
    }

    function setStorageToken(address _token) public onlyOwner {				
        StorageToken = IERC20Burnable(_token);				
    }

    function setStorageNFT(address _token) public onlyOwner {				
        StorageNFT = IStorageNFT(_token);				
    }

    function mint(address to,uint amount) public onlyOwner {				
        StorageToken.mint(to,amount);			
    }

    function safeMint(address to, uint256 tokenId, string memory uri, IStorageNFT.MetaData memory metaData)public onlyOwner {				
        StorageNFT.safeMint(to,tokenId,uri,metaData);			
    }

}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
pragma solidity ^0.8.11;

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
}


interface IStorageNFT is IERC721 {
    struct MetaData {
        string  uuid;
        uint size;
        string attr1;
        string attr2;
        string attr3;
        string attr4;
        string attr5;
    }

    function safeMint(address to, uint256 tokenId, string memory uri, MetaData memory metaData) external;
    function tokenMetaData(uint256 tokenId) external view returns (MetaData memory);
    function burn(uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view  returns (uint256);
    function tokenByIndex(uint256 index) external view  returns (uint256);
    function totalSupply() external view  returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}