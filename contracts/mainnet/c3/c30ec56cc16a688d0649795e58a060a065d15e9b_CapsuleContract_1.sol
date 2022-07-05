/**
 *Submitted for verification at polygonscan.com on 2022-07-05
*/

// File: utils/ICapsuleContract.sol

pragma solidity >=0.8.0 <0.9.0;

interface ICapsuleContract{
    function writePriceInfo(uint256 price) external;
    function getPriceInfo() external view returns(uint256 price,uint256 time);
    function createCapsule(address caller,bool triple) external returns(uint256[] memory, uint256);
    function setELFCoreAddress(address addr) external;
}
// File: security/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}
// File: CapsuleContract_1.sol

pragma solidity >=0.8.0 <0.9.0;



contract CapsuleContract_1 is ICapsuleContract, AccessControl{

    /// @dev Label of all capsules createdd by this contract.
    uint256 public constant label=0;

    /// @dev Minimum price of capsule.
    uint256 public constant minPrice=75000000000000000000;

    /// @dev The time when last sale occurs. It's initial value is when the contract is deployed.
    uint256 public lastSale;

    /// @dev Last price of capsule.
    uint256 lastPrice=75000000000000000000;

    /// @dev Time of end of sale.
    uint256 public constant endAt=1655553599;

    /// @dev Maximum number of capsules this capsule machine can generate.
    uint256 public constant maxCapsuleNumber=100;

    /// @dev Counter of created capsules.
    uint256 public capsuleNumberCount;

    /// @dev Address of ELFCore contract.
    address public ELFCoreAddress;

    /// @dev ID table for all possible parts.
    mapping (uint256 => uint256[42]) IDTable;

    /// @dev Probability table for all possible parts.
    mapping (uint256 => uint256[42]) probabilityTable;

    constructor(){
        lastSale=block.timestamp;
        for (uint256 index=0;index<3;index++){
            for (uint256 index2=0;index2<30;index2++){
                IDTable[index][index2]=(1+index2/5)*10+index2%5+1;
                if (index2<15){
                    if ((index2+1)%5!=0){
                        probabilityTable[index][index2]=50370;
                    }
                    else{
                        probabilityTable[index][index2]=11848;
                    }
                }
                else{
                    if ((index2+1)%5!=0){
                        probabilityTable[index][index2]=28335;
                    }
                    else{
                        probabilityTable[index][index2]=6665;
                    }
                }
            }
        }
        for (uint256 index=3;index<7;index++){
            for (uint256 index2=0;index2<42;index2++){
                IDTable[index][index2]=(1+index2/7)*10+index2%7+1;
                if (index2<21){
                    if ((index2+1)%7!=0){
                        probabilityTable[index][index2]=33580;
                    }
                    else{
                        probabilityTable[index][index2]=11853;
                    }
                }
                else{
                    if ((index2+1)%7!=0){
                        probabilityTable[index][index2]=18890;
                    }
                    else{
                        probabilityTable[index][index2]=6660;
                    }
                }
            }
        }
        probabilityTable[0]=[70835,70835,70835,70835,16663,70835,70835,70835,70835,16663,70835,70835,70835,70835,16663,7870,7870,7870,7870,1850,7870,7870,7870,7870,1850,7870,7870,7870,7870,1850,0,0,0,0,0,0,0,0,0,0,0,0];
    }

    /// @dev Throws if called by any account other than the ELFCoreAddress.
    modifier onlyELFCore{
        require(msg.sender==ELFCoreAddress,NO_PERMISSION);
        _;
    }

    function setELFCoreAddress(address addr) external override onlySuperAdmin {
        require(addr!=address(0),INVALID_ADDRESS);
        ELFCoreAddress=addr;
    }

    function writePriceInfo(uint256 price) external onlyAdmin override{ 
        require(price>=minPrice,'wrong parameter');
        lastPrice=price;
        lastSale=block.timestamp;
    }

    function getPriceInfo() external view override returns(uint256,uint256){
        require(block.timestamp<=endAt,'expired');   
        return(lastPrice,block.timestamp-lastSale);
    }

    function createCapsule(address caller,bool triple) external override onlyELFCore returns(uint256[] memory, uint256){
        uint256 count=1;
        if (triple){
            count=3;
        }
        capsuleNumberCount+=count;
        require(capsuleNumberCount<=maxCapsuleNumber,'sold out');
        lastPrice=lastPrice*101**count/100**count;
        uint256 seed=lastSale+uint256(uint160(caller))+capsuleNumberCount;
        uint256[] memory res = new uint256[](count);
        for (uint256 i2=0;i2<count;i2++){
            (res[i2],seed)=generateGene(seed);
        }
        return (res,label);
    }

    function generateGene(uint256 seed) internal view returns(uint256,uint256){
        uint256 tempSeed=seed;
        uint256 gene;
        for (uint256 round=0;round<7;round++){
            uint256[42] memory partProbability=probabilityTable[round];
            uint256[42] memory partID=IDTable[round];
            for (uint256 i=0;i<3;i++){
                seed=uint256(sha256(abi.encodePacked(seed)))%999999+1;
                uint256 tempSum=0;
                uint256 index=0;
                while (tempSum<seed){
                    tempSum+=partProbability[index];
                    index+=1;
                }
                seed+=tempSeed;
                tempSeed=seed;
                gene+=((round+1)*100+partID[index-1])*1000**(20-round*3-i);
            }
        }
        return (gene,seed);
    }
}