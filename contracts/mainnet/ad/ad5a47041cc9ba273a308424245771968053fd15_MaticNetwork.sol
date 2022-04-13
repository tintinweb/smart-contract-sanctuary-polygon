/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

pragma solidity 0.4.25; 

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address public owner;
    address public newOwner;
    address public  signer;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }
    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /**
     * This function checks if given address is contract address or normal wallet
     * EXTCODESIZE returns 0 if it is called from the constructor of a contract.
     * so multiple check is required to assure caller is contract or not
     * for this two hash used one is for empty code detector another is if 
     * contract destroyed.
     */
    function extcodehash(address addr) internal view returns(uint8)
    {
        bytes32 accountHash1 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // for empty
        bytes32 accountHash2 = 0xf0368292bb93b4c637d7d2e942895340c5411b65bc4f295e15f2cfb9d88dc4d3; // with selfDistructed        
        bytes32 codehash = codehash = keccak256(abi.encodePacked(addr));
        if(codehash == accountHash2) return 2;
        codehash = keccak256(abi.encodePacked(at(addr)));
        if(codehash == accountHash1) return 0;
        else return 1;
    }
    // This returns bytecodes of deployed contract
    function at(address _addr) internal view returns (bytes o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
  
    }
    function isContract(address addr) internal view returns (uint8) {

        uint8 isCon;
        uint32 size;
        isCon = extcodehash(addr);
        assembly {
            size := extcodesize(addr)
        } 
        if(isCon == 1 || size > 0 || msg.sender != tx.origin ) return 1;
        else return isCon;
    }


}  
    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract MaticNetwork is owned {
    
    uint public joiningFee = 10 * (10 ** 18 );     
    uint public lastIDCount = 0; 

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint placeCount;
        uint oddOf;
        uint earnedTotal;
        uint missedTotal;
        address[] direct;
    }


    mapping (address => userInfo) public userInfos;
    mapping (uint => address ) public userAddressByID;


    event joinPartyEv(address _newUser, uint newUserId, address referedBy,uint oddEven, uint timeNow);
    event paidEv(address paidTo, uint amount, address paidFor, uint OddEven , uint timeNow);

    constructor() public {
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            placeCount: 1, 
            oddOf: 1,
            earnedTotal:0,
            missedTotal:0,
            direct: new address[](0)
        });
        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;
        emit joinPartyEv(msg.sender,1, msg.sender, 1, now);
    }

    function joinParty(address referedBy) public payable returns(bool)
    {
        require(isContract(msg.sender) ==0, "Contract can't call");
        require(userInfos[referedBy].joined, "referrer does not exits");
        require(!userInfos[msg.sender].joined, "sender already joined");
        require(msg.value == joiningFee, "Invalid amount sent");

        userInfos[referedBy].direct.push(referedBy);
        uint len = userInfos[referedBy].direct.length;

        lastIDCount++;

        uint refId = userInfos[referedBy].id;

        userInfo memory temp;
        temp.joined = true;
        temp.id = lastIDCount;
        temp.referrerID = refId;
        temp.placeCount = len;

        uint OE = len % 2;

        if (OE == 1) temp.oddOf = refId;
        else temp.oddOf = userInfos[referedBy].oddOf;

        userInfos[msg.sender] = temp;
        

        userAddressByID[temp.id] = msg.sender;
        uint   amount;
        if (OE == 1 ) 
        {
         amount=msg.value;

            referedBy.transfer((amount*88)/100);
            userAddressByID[1].transfer((amount*12)/100);
            userInfos[referedBy].earnedTotal += (amount*88)/100;//msg.value;
            emit paidEv(referedBy, msg.value, msg.sender, OE , now);
        }
        else 
        {
          //  referedBy.transfer(msg.value/2);
          amount=msg.value/2;
            referedBy.transfer((amount*88)/100);
            // referedBy.transfer(amount.mul(88).div(100));
             userAddressByID[1].transfer((amount*12)/100);
            userInfos[referedBy].earnedTotal += (amount*88)/100;//msg.value/2;
            address _oddOff = userAddressByID[temp.oddOf];

            if( userInfos[_oddOff].direct.length >= len ) 
            {
                _oddOff.transfer((amount*88)/100);
                 userAddressByID[1].transfer((amount*12)/100);
                userInfos[_oddOff].earnedTotal += ((amount*88)/100);
                emit paidEv(_oddOff, msg.value/2, msg.sender, OE , now);
            }
            else
            {
                userAddressByID[1].transfer(msg.value/2);
                userInfos[_oddOff].missedTotal += msg.value/2;
                emit paidEv(address(0), msg.value/2, msg.sender, OE , now);
            }

        }

        emit joinPartyEv(msg.sender,temp.id, referedBy, OE, now);

    }


}