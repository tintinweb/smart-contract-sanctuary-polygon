// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

   
import "../node_modules/@OpenZeppelin/contracts/access/AccessControl.sol";
import "../node_modules/@OpenZeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@OpenZeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; 
import "../node_modules/@OpenZeppelin/contracts/security/ReentrancyGuard.sol";
import "./DateUtil.sol";
 

interface IRefStore {
    /// referrer
    function referrer(address from) external view returns (address);
    /// add referrer
    function addReferrer(address from, address to) external;
    /// referrer added
    event ReferrerAdded(address indexed to, address from);
}

struct MetaData {
        uint64 specialty;
        uint64 comfort;
        uint64 aesthetic;
        uint32 durability;
        uint32 level;
}

interface IRunbitCard is IERC721, IERC721Enumerable{
    function safeMint(address to, uint256 tokenId, string memory uri, MetaData memory metaData) external;
    
}


contract Layer is AccessControl, DateUtil,ReentrancyGuard{
    mapping(address => address) public referrer;
    event ReferrerAdded(address indexed to,address from);
    event TransferToken(address indexed from,address indexed to,uint amount);
    //event CheckAmount(address indexed from,uint indexed amount);
    event BuyRB(address indexed from,uint indexed amount);
    event PromotionAward(address indexed from,address to,uint indexed amount);
    event Devidend(address indexed from,address to,uint indexed amount);
    event InCome(address indexed to,string date,uint amount);
    
    address public tokenAddress;
    address public NFTAddress;
    address public recipient;
    address public refStoreAddress;
    //address public RBToken;
    uint public startDate;

    string mbaseUri = "https://runbit.org/pict/";    
    
    struct FunderDetail {
        uint numTimes;
        uint amount;
        bool isUsed;
    }
    mapping(address => FunderDetail) public Details;
    
    struct IncomesDetail {
        uint numTimes;
        uint amount;
        bool isUsed;
        bool isDealed;
    }   
    
    mapping(string => IncomesDetail) public Incomes;

    
    struct Card {
        uint index;
        string uri;
    }   
    
    Card[] public cards;

    //class 
    mapping(string => address[]) public class1;
    mapping(string => address[]) public class2;
    mapping(string => address[]) public class3;

    //mapping(address => uint) public UserGrade;
    mapping(address => uint) public UserRBTotal;
    mapping(string => bool) public dealStatus;

    constructor(address _token, address _recipient, address _refStoreAddress, address _NFTAddress)  {
        tokenAddress = _token;
        recipient = _recipient;
        refStoreAddress = _refStoreAddress;
        //RBToken = _RBToken;
	NFTAddress = _NFTAddress;
        uint year;
        uint month;
        uint day;
        (year,month,day) = DateUtil.daysToDate(int(block.timestamp),8);
        startDate = DateUtil.toTimestamp0(uint16(year),uint8(month),uint8(day));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //
    function initUser(address to) external   {
        FunderDetail storage f = Details[to];
        require(f.amount > 0 ,"Invalid Referrer");
        require(referrer[msg.sender] == address(0), 'Layer::addReferrer: alreday add!');
        require(referrer[to] != address(0), 'Layer::addReferrer: invalid referrer!');
        _addReferrer(msg.sender, to);
    }

    //
    function _addReferrer(address from, address to) private {
        referrer[from] = to;
        IRefStore refStore = IRefStore(refStoreAddress);
        refStore.addReferrer(from,to);
        emit ReferrerAdded(to, from);
    }

    function addReferrer(address from, address to) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _addReferrer(from, to);
    }

    function getDay() public view returns (uint daysNum){
         daysNum = (block.timestamp-startDate)/(24*60*60);
    }
    
    function getRequestAmount() public view returns (uint amountByDay){
        uint daysNum = (block.timestamp-startDate)/(24*60*60);
        amountByDay = 180000000 + 10000000*daysNum;
    }

    mapping(string => uint) public dayLimit;

    function transfer(uint amount) external nonReentrant() returns (bool result)  {
       require(cards.length <= 1000 ," Cards sold out");
       require(getDay() <= 24 ,"Time over");
       string memory date = DateUtil.daysToDateString(int(block.timestamp),8);  
       require(dayLimit[date] <= 66 ,"Exceed the purchase limit");       
        
       FunderDetail storage f = Details[msg.sender];
       require(!(f.amount > 0 ),"User has subscribed");       
       require(amount == getRequestAmount() ,"Amount incorrect");      
        
       IERC20 wowToken = IERC20(tokenAddress); 
       uint m = wowToken.balanceOf(msg.sender);
       //emit CheckAmount(msg.sender,m);
       require(m >= getRequestAmount() ,"Transfer amount exceeds user balance");

       wowToken.transferFrom(msg.sender,recipient,amount);
       emit TransferToken(msg.sender,recipient,amount);

       if(!Details[msg.sender].isUsed){
            FunderDetail storage t = Details[msg.sender];
            t.amount = 0;
            t.numTimes = 0;
            t.isUsed = true;
        }
       FunderDetail storage d = Details[msg.sender];
       d.amount += amount;
       d.numTimes++;
       //d.times[d.numTimes++] = amount;      
       
       if(!Incomes[date].isUsed){
            IncomesDetail storage incomesDetail= Incomes[date];
            incomesDetail.amount = 0;
            incomesDetail.numTimes = 0;
            incomesDetail.isUsed = true;
        }       
       IncomesDetail storage iDetail= Incomes[date];
       iDetail.amount += amount;
       iDetail.numTimes++;
       mintx();

       dayLimit[date]++;
       
       //transfer to superUser
       wowToken.transferFrom(recipient,referrer[msg.sender],amount*10/100);      

       emit PromotionAward(msg.sender,referrer[msg.sender],amount*10/100);       
       emit InCome(msg.sender,date,amount);

       return true;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    
    function mintx()  private {
        IRunbitCard Runbit = IRunbitCard(NFTAddress); 
        MetaData memory metaData = MetaData(60000, 8500, 8500, 9000, 4);
        require(Runbit.balanceOf(msg.sender) == 0);       
        uint id = cards.length + 100001;
        string memory muri = DateUtil.strConcat(mbaseUri,DateUtil.uintToString(id));
        cards.push(Card(id, DateUtil.strConcat(muri,".png")));

        Runbit.safeMint(msg.sender,id,DateUtil.strConcat(muri,".png"),metaData);
    }
    

    //�û����ڲ㼶  ����--�û�--�㼶
    mapping(string => mapping (address => uint) ) public classList; 
    
    //���������
    mapping(address => uint ) public dealTimeList;
    
    //ÿ�յķֺ�
    struct dividendByDay {
        uint class1;
        uint class2;
        uint class3;
    }   
    
    //����--�ֺ�
    mapping(string => dividendByDay) public dividendByDayList;


    function updateClass(address[] memory userAddress,uint userClass) external{
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
         require(userClass == 1 || userClass == 2 || userClass == 3  ,"No such class");
         string memory date = DateUtil.daysToDateString(int(block.timestamp - 1 days),8);
         require(!dealStatus[date],"Already completed");
         for(uint i=0;i<userAddress.length;i++){
            if(userClass == 1){
                class1[date].push(userAddress[i]);
                classList[date][userAddress[i]] = 1;
            }else if(userClass == 2){
                class2[date].push(userAddress[i]);
                classList[date][userAddress[i]] = 2;
            }else if(userClass == 3){
                class3[date].push(userAddress[i]);
                classList[date][userAddress[i]] = 3;
            }
         }

    }

    function getClass1List(string memory date) external view returns(address[] memory  ){
       return class1[date];
    }

    function getClass2List(string memory date) external view returns(address[] memory ){
        return class2[date];
    }

    function getClass3List(string memory date) external view returns(address[] memory ){
        return class3[date];
    }

       
    function class1Length(string memory date) external view returns(uint){
        address[] memory x = class1[date];
        return x.length;
    }
       
    function class2Length(string memory date) external view returns(uint){
        address[] memory x = class2[date];
        return x.length;
    }
       
    function class3Length(string memory date) external view returns(uint){
        address[] memory x = class3[date];
        return x.length;
    }
    

    function clearClass() external{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        
        string memory date = DateUtil.daysToDateString(int(block.timestamp - 1 days),8);
        require(!dealStatus[date],"Operation rejected");
        for (uint i=0;i<class1[date].length;i++){
             delete classList[date][class1[date][i]];
        }
        for (uint i=0;i<class2[date].length;i++){
            delete classList[date][class2[date][i]];
        }
        for (uint i=0;i<class3[date].length;i++){
            delete classList[date][class3[date][i]];
        }

        delete class1[date];
        delete class2[date];
        delete class3[date];
        //delete classList[date];
    }



    function dividend() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");     

        string memory date = DateUtil.daysToDateString(int(block.timestamp - 1 days),8);
        require(!dealStatus[date], "Dividends have been completed") ;      

        uint amount = Incomes[date].amount;
        uint in_class1;
        uint in_class2;
        uint in_class3;
        if(class1[date].length > 0){
            in_class1 = (amount*5/100)/class1[date].length;
        }
        if(class2[date].length > 0){
            in_class2 = (amount*3/100)/class2[date].length;
        }
        if(class3[date].length > 0){
            in_class3 = (amount*2/100)/class3[date].length;
        }

        dividendByDayList[date] = dividendByDay(in_class1,in_class2,in_class3);

        dealStatus[date] = true;
    }


    function getday0(uint timestamp) private pure returns (uint){
        uint year;
        uint month;
        uint day;
        (year,month,day) = DateUtil.daysToDate(int(timestamp),8);
        uint thisDay = DateUtil.toTimestamp0(uint16(year),uint8(month),uint8(day));
        return thisDay;
    }

    //1. ��ȡdealTimeList���õ�������dealtime
    //2. ��������dealtime��ʼѭ����0��ȡ����ʱ�䣩����dividendByDayListȡ����ķ����жϼ���
    function dividendOf(address userAddress) public view returns(uint){
        uint _lastDealtime = dealTimeList[userAddress];
        if (_lastDealtime == 0) {
            _lastDealtime = startDate;
        }
        //ת��0��
        _lastDealtime = getday0(_lastDealtime);
        //today.  00:00:00 timestamp
        uint today = getday0(block.timestamp) ;
       
        uint userBonus = 0;

        for (uint lastDealtime = _lastDealtime ;lastDealtime <= today - 1 days ; lastDealtime = (lastDealtime + 1 days)) {
            string memory tempDate = DateUtil.daysToDateString(int(lastDealtime),8);
            //�Ñ����e
            if(classList[tempDate][userAddress] == 1){
                userBonus = userBonus + dividendByDayList[tempDate].class1;
            }
            if(classList[tempDate][userAddress] == 2){
                userBonus = userBonus + dividendByDayList[tempDate].class2;
            }
            if(classList[tempDate][userAddress] == 3){
                userBonus = userBonus + dividendByDayList[tempDate].class3;
            }

        }

        return userBonus;

    }



    mapping (address => uint) public userDealedBonus;

    //��ȡ�ֺ�
    function getBonus() public nonReentrant() {
        uint bonus = dividendOf(msg.sender);
        require(bonus > 0,"Invalid amount");       
      
        //�����Ƿ��Ѿ��ֺ�
        string memory date = DateUtil.daysToDateString(int(block.timestamp - 1 days),8);
        if(!dealStatus[date]){
            //����û�ֺ�
            dealTimeList[msg.sender] = block.timestamp - 1 days;
        }else{
            dealTimeList[msg.sender] = block.timestamp;
        }

        //�����û��ֺ��¼
        userDealedBonus[msg.sender] = userDealedBonus[msg.sender] + bonus;
        //transfer
        _devidendSend(msg.sender, bonus);
    }


    struct Bonus {
        uint time;
        uint amount;
    }
    mapping (address => Bonus[]) public bonusDetail;

    function _devidendSend(address _add, uint _amount) private{
        IERC20 wowToken = IERC20(tokenAddress); 
        wowToken.transferFrom(recipient,_add,_amount);
        bonusDetail[msg.sender].push(Bonus(block.timestamp,_amount));
        emit Devidend(recipient,_add,_amount);
    }
    
    function getBonusDetailList(address _addr) external view returns(Bonus[] memory){
        return bonusDetail[_addr];
    }


    mapping (address => mapping (uint => bool) ) public buyRBStatus;

    function buyRB(uint Rbnum) external{
        require(getDay() <= 24 ,"Time over");
	    //��ѯ������û�����
        string memory date = DateUtil.daysToDateString(int(block.timestamp - 1 days),8);   
        require(classList[date][msg.sender] != 0,"Invalid user");
        uint total;
        if(classList[date][msg.sender] == 1){
            total = 1000;
            require(!(buyRBStatus[msg.sender][1]),"Repeat purchase");
            buyRBStatus[msg.sender][1] = true;
        }else if(classList[date][msg.sender] == 2){
            total = 5000;
            require(!(buyRBStatus[msg.sender][2]),"Repeat purchase");
            buyRBStatus[msg.sender][2] = true;
        }else if(classList[date][msg.sender] == 3){
            total = 10000;
            require(!(buyRBStatus[msg.sender][3]),"Repeat purchase");
            buyRBStatus[msg.sender][3] = true;
        }

        require(Rbnum == total,"Invalid RBnum");
        //require(UserRBTotal[msg.sender]+Rbnum <= total,"exceed user limit");   

        UserRBTotal[msg.sender] = UserRBTotal[msg.sender] + Rbnum;

        // USDT num (500u -to- 1000RB)
        uint USDTnum = (Rbnum * 1000000)/2;  

        //������뵱��
        date = DateUtil.daysToDateString(int(block.timestamp),8);           

        if(!Incomes[date].isUsed){
            IncomesDetail storage incomesDetail= Incomes[date];
            incomesDetail.amount = 0;
            incomesDetail.numTimes = 0;
            incomesDetail.isUsed = true;
        }
       
       IncomesDetail storage iDetail= Incomes[date];
       iDetail.amount += USDTnum;
       iDetail.numTimes++;

       IERC20 wowToken = IERC20(tokenAddress); 
       wowToken.transferFrom(msg.sender,recipient,USDTnum);

       emit BuyRB(msg.sender,Rbnum);
       emit InCome(msg.sender,date,USDTnum);

    }


    function updateMbaseUrl(string memory _uri) external{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        mbaseUri = _uri;
    }



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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

contract DateUtil {
 
    uint constant internal SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant internal SECONDS_PER_HOUR = 60 * 60;
    uint constant internal SECONDS_PER_MINUTE = 60;
    uint constant internal OFFSET19700101 = 2440588;
    uint constant internal YEAR_IN_SECONDS = 31536000;
    uint constant internal LEAP_YEAR_IN_SECONDS = 31622400;
    uint16 constant internal ORIGIN_YEAR = 1970;
 
   
 
    //时间戳转日期
    function daysToDate(int timestamp, int8 timezone) public pure returns (uint year, uint month, uint day){
        return _daysToDate(timestamp + timezone * int(SECONDS_PER_HOUR));
    }
    
    function daysToDateString(int timestamp, int8 timezone) public pure returns (string memory dateTime){
        return _daysToDateString(timestamp + timezone * int(SECONDS_PER_HOUR));
    }

 
    //时间戳转日期，UTC时区
    function _daysToDate(int timestamp) private pure returns (uint year, uint month, uint day) {
        uint _days = uint(timestamp) / SECONDS_PER_DAY;
 
        uint L = _days + 68569 + OFFSET19700101;
        uint N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * year / 4 + 31;
        month = 80 * L / 2447;
        day = L - 2447 * month / 80;
        L = month / 11;
        month = month + 2 - 12 * L;
        year = 100 * (N - 49) + year + L;
    }
    
    
    //时间戳转日期，UTC时区
    function _daysToDateString(int timestamp) private pure returns (string memory dateTime) {
        uint   year;
        uint   month;
        uint   day;
        
        (year, month,  day) = _daysToDate(timestamp);
        string memory m;
        string memory d;
        // if(month<10){
        //     m = strConcat("0",uintToString(month));
        // }else{
        //     m = uintToString(month);
        // }  
        month<10 ?  m = strConcat("0",uintToString(month)) :  m = uintToString(month);
        day<10 ? d = strConcat("0",uintToString(day)) : d = uintToString(day);         
        dateTime=strConcat(m,d);
    }

    
    
        
    function uintToString(uint _uint) public pure returns (string memory str) {

        if(_uint==0) return '0';

        while (_uint != 0) {
            //取模
            uint remainder = _uint % 10;
            //每取一位就移动一位，个位、十位、百位、千位……
            _uint = _uint / 10;
            //将字符拼接，注意字符位置
            str = strConcat(toStr(remainder),str);
        }

    }
    
     //这个函数用来连接两个字符串 'aaa' + 'bbb' =>  'aaabbb'
    function strConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }    
    
 
    function toStr(uint256 value) private pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        //这里把数字转成了bytes32类型，但是因为我们知道数字是 0-9 ，所以前面其实都是填充了0
        bytes memory data = abi.encodePacked(value);
        bytes memory str = new bytes(1);
        //所以最后一位才是真正的数字
        uint i = data.length - 1;
        str[0] = alphabet[uint(uint8(data[i] & 0x0f))];
        return string(str);
    }
    
    function isLeapYear(uint16 year) private pure returns (bool) {
            if (year % 4 != 0) {
                    return false;
            }
            if (year % 100 != 0) {
                    return true;
            }
            if (year % 400 != 0) {
                    return false;
            }
            return true;
        }

    function leapYearsBefore(uint year) private pure returns (uint) {
            year -= 1;
            return year / 4 - year / 100 + year / 400;
        }
    
    function toTimestamp0(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
            return toTimestamp(year, month, day, 0, 0, 0) - 8*60*60;
        }
    
    
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) private pure returns (uint timestamp) {
            uint16 i;

            // Year
            for (i = ORIGIN_YEAR; i < year; i++) {
                    if (isLeapYear(i)) {
                            timestamp += LEAP_YEAR_IN_SECONDS;
                    }
                    else {
                            timestamp += YEAR_IN_SECONDS;
                    }
            }

            // Month
            uint8[12] memory monthDayCounts;
            monthDayCounts[0] = 31;
            if (isLeapYear(year)) {
                    monthDayCounts[1] = 29;
            }
            else {
                    monthDayCounts[1] = 28;
            }
            monthDayCounts[2] = 31;
            monthDayCounts[3] = 30;
            monthDayCounts[4] = 31;
            monthDayCounts[5] = 30;
            monthDayCounts[6] = 31;
            monthDayCounts[7] = 31;
            monthDayCounts[8] = 30;
            monthDayCounts[9] = 31;
            monthDayCounts[10] = 30;
            monthDayCounts[11] = 31;

             for (i = 1; i < month; i++) {
                    timestamp += SECONDS_PER_DAY * monthDayCounts[i - 1];
            }

            // Day
            timestamp += SECONDS_PER_DAY * (day - 1);

            // Hour
            timestamp += SECONDS_PER_HOUR * (hour);

            // Minute
            timestamp += SECONDS_PER_MINUTE * (minute);

            // Second
            timestamp += second;
            return timestamp;
        }
    
}