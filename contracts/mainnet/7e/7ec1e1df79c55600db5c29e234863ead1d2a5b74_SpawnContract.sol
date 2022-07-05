/**
 *Submitted for verification at polygonscan.com on 2022-07-05
*/

// File: utils/ISpawnContract.sol

pragma solidity >=0.8.0 <0.9.0;

interface ISpawnContract{

    /// @dev This event should be fired whenever the address of CoinB is modified.
    event CoinBChanged(address indexed _from,address indexed _to, uint256 _time);

    /// @dev This event should be fired whenever the address of CoinA is modified.
    event CoinAChanged(address indexed _from,address indexed _to, uint256 _time);

    /// @dev Change CoinA contract.
    ///  Caller should always be superAdmin. _to is the address of new CoinA contract.
    function changeCoinA(address addr) external;

    /// @dev Change CoinB contract.
    ///  Caller should always be superAdmin. _to is the address of new CoinB contract.
    function changeCoinB(address addr) external;

    function setELFCore(address addr) external;

    function spawnEgg(uint256 seed, uint256 momGene, uint256 dadGene, uint256 momChildren, uint256 dadChildren, address caller, bool momFromChaos, bool dadFromChaos) external returns(uint256 gene);
}
// File: utils/ISpawnCoin.sol

pragma solidity >=0.8.0 <0.9.0;

interface ISpawnCoin {

    event SpawnContractAddressChanged(address indexed _from, address indexed _to, uint256 time);

    function setSpawnContractAddress(address addr) external;

    function spawnEgg(address addr,uint256 amount) external;
  
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
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: SpawnContract.sol

pragma solidity >=0.8.0 <0.9.0;




contract SpawnContract is Pausable, ISpawnContract{

    /// @dev Address of ELFCore.
    address public ELFCore;
    /// @dev The address of CoinA.
    address public coinAAddress;
    /// @dev The address of CoinB.
    address public coinBAddress;

    function setELFCore(address addr) external override onlySuperAdmin {
        require(addr!=address(0),INVALID_ADDRESS);
        ELFCore=addr;
    }

    /// @dev Change CoinA contract.
    ///  Caller should always be superAdmin. _to is the address of new CoinA contract.
    function changeCoinA(address addr) external override onlySuperAdmin{
        require(addr!=address(0),INVALID_ADDRESS);
        emit CoinAChanged(coinAAddress,addr,block.timestamp);
        coinAAddress=addr;
    }

    /// @dev Change CoinB contract.
    ///  Caller should always be superAdmin. _to is the address of new CoinB contract.
    function changeCoinB(address addr) external override onlySuperAdmin{
        require(addr!=address(0),INVALID_ADDRESS);
        emit CoinBChanged(coinBAddress,addr,block.timestamp);
        coinBAddress=addr;
    }

    function spawnEgg(uint256 seed, uint256 momGene, uint256 dadGene, uint256 momChildren, uint256 dadChildren, address caller, bool momFromChaos, bool dadFromChaos) external override returns(uint256 gene){
        require(msg.sender==ELFCore,NO_PERMISSION);
        gene=spawnGene(seed+uint256(uint160(caller)),momGene,dadGene);
        ISpawnCoin coinAInstance=ISpawnCoin(coinAAddress);
        coinAInstance.spawnEgg(caller,2000000);
        ISpawnCoin coinBInstance=ISpawnCoin(coinBAddress);
        coinBInstance.spawnEgg(caller,coinBAmount(momChildren,momFromChaos)+coinBAmount(dadChildren,dadFromChaos));
    }

    /// @dev Internal function which calculate amount of coinB an ELF cost in a spawn event.
    function coinBAmount(uint256 l, bool fromChaos) internal pure returns(uint256 res){
        if (!fromChaos){
            if (l==0){
                res=900;
            }
            else if (l==1){
                res=1200;
            }
            else if (l==2){
                res=1800;
            }
            else if (l==3){
                res=3300;
            }
            else if (l==4){
                res=5700;
            }
            else if (l==5){
                res=9000;
            }
            else if (l==6){
                res=15000;
            }
        }
    }

    /// @dev Generate gene of child.
    function spawnGene(uint256 seed,uint256 mom,uint256 dad) internal pure returns(uint256 gene){
        if ((isPure(mom)==3 && isPure(dad)==6)||(isPure(mom)==6 && isPure(dad)==3)){
            gene=generateGene(90,mom,dad,seed);
        }
        else if ((isPure(mom)==1 && isPure(dad)==4)||(isPure(mom)==4 && isPure(dad)==1)){
            gene=generateGene(70,mom,dad,seed);
        }
        else if ((isPure(mom)==5 && isPure(dad)==2)||(isPure(mom)==2 && isPure(dad)==5)){
            gene=generateGene(80,mom,dad,seed);
        }
        else{
            gene=generateGene(0,mom,dad,seed);
        }
    }

    /// @dev If the given gene is pure, returns its attribute index, else returns 0.
    function isPure(uint256 gene) internal pure returns(uint256){
         uint256 ref=(gene/10000000)%10;
         for(uint256 i=1;i<7;i++){
             if((gene/(10**(7+9*i)))%10!=ref){
                 return 0;
             }
         }
        return ref;
    }

    ///@dev Generate all gene (major, minor and last).
    function generateGene(uint256 attribute,uint256 mom,uint256 dad,uint256 seed) internal pure returns(uint256 gene){
        uint256[6] memory idTable;
        uint256[6] memory probabilityTable;
        uint256 tempSum;
        uint256 index;
        uint div;
        uint256 tempSeed=seed;
        uint256 l;
        for (uint256 i=0;i<7;i++){
            probabilityTable=[uint256(3),9,38,3,9,38];
            for (uint256 i2=0;i2<3;i2++){// generate idTable for this part
                idTable[i2]=mom%1000;
                mom=mom/1000;
                idTable[i2+3]=dad%1000;
                dad=dad/1000;
            }
            seed=uint256(sha256(abi.encodePacked(seed)))%100+1;
            l=5;
            if (attribute!=0 && seed<9){
                seed+=tempSeed;
                tempSeed=seed;
                if (i==4||i==5){//ear and eyes have only two partIds
                    seed=uint256(sha256(abi.encodePacked(seed)))%2+1;
                }
                else{//other parts have threee partIds
                    seed=uint256(sha256(abi.encodePacked(seed)))%3+1;
                }
                gene=gene+((7-i)*100+attribute+seed)*10**(i*9+6);//special major
                seed+=tempSeed;
                tempSeed=seed;
                div=100;
            }
            else{
                tempSum=0;
                index=0;
                while (tempSum<seed){
                    tempSum+=probabilityTable[index];
                    index+=1;
                }
                seed+=tempSeed;
                tempSeed=seed;
                index-=1;
                gene+=idTable[index]*10**(i*9+6);//normal major
                div=100-probabilityTable[index];
                idTable[index]=idTable[l];
                probabilityTable[index]=probabilityTable[l];
                l-=1;
            }
            seed=uint256(sha256(abi.encodePacked(seed)))%div+1;
            tempSum=0;
            index=0;
            while (tempSum<seed){
                tempSum+=probabilityTable[index];
                index+=1;
            }
            seed+=tempSeed;
            tempSeed=seed;
            index-=1;
            gene+=idTable[index]*10**(i*9+3);//minor
            div-=probabilityTable[index];
            idTable[index]=idTable[l];
            probabilityTable[index]=probabilityTable[l];
            seed=uint256(sha256(abi.encodePacked(seed)))%div+1;
            tempSum=0;
            index=0;
            while (tempSum<seed){
                tempSum+=probabilityTable[index];
                index+=1;
            }
            gene+=idTable[index-1]*10**(i*9);//last
            seed+=tempSeed;
            tempSeed=seed;
        }
    }
}