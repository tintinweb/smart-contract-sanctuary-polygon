/**
 *Submitted for verification at polygonscan.com on 2022-02-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/


pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED



interface ERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


    
interface EcosystemContract{
    function isEngineContract( address _address ) external returns (bool);
    function returnAddress ( string memory _contractName ) external returns ( address );
}

interface WarbotManufacturer{

    function  setTokenURIEngine ( uint256 tokenId, string memory __tokenURI) external;
    function ownerOf ( uint256 _tokenid ) external returns ( address );
}


contract WarbotNameChanger is Ownable  {
    uint256 public oraclefee;
    EcosystemContract public ecosystem;
    address public ecosystemaddress;
    address public EmergencyAddress;
    address public warbotmanufactureraddress;
    WarbotManufacturer public warbotmanufacturer;
   

   mapping ( uint256 => Request ) public Requests;
   mapping ( uint256 => uint256 ) public warbotNameChangeCount;

   uint256 public nameChangeRequestNumber;
   uint256 public nameChangeRequestNumberProcessed;

  struct Request {
      uint256 _tokenid;
      bool _completed;
  }

   

   constructor ( address _ecosystem ){
        ecosystemaddress = _ecosystem;
        ecosystem = EcosystemContract ( ecosystemaddress );
        EmergencyAddress = msg.sender;
        oraclefee = 1000000000000000000;
        warbotmanufactureraddress =  ecosystem.returnAddress("WarbotManufacturer");
        warbotmanufacturer = WarbotManufacturer ( warbotmanufactureraddress );
   }

    function setOracleFee ( uint256 _fee ) public onlyOwner{
        require ( _fee < 100000000000000000 && _fee > 1000000000000000 );
         oraclefee = _fee;
    }

   function updateEcosystemAddress ( address _address ) public onlyOwner {
       ecosystemaddress = _address;
       ecosystem = EcosystemContract ( ecosystemaddress );
       warbotmanufactureraddress =  ecosystem.returnAddress("WarbotManufacturer");
       warbotmanufacturer = WarbotManufacturer ( warbotmanufactureraddress );

   }
   
   function nameMyWarbot ( uint256 _tokenid ) public payable {
        
        require ( warbotmanufacturer.ownerOf( _tokenid ) == msg.sender, "Not the owner" );
        warbotNameChangeCount[_tokenid]++;
        require ( msg.value ==  warbotNameChangeCount[_tokenid] * oraclefee , "Oracle fee incorrect" );
        nameChangeRequestNumber++;
        Requests[nameChangeRequestNumber]._tokenid = _tokenid;

        payable(ecosystem.returnAddress("Oracle")).transfer( address(this).balance );
    }

    

    function process ( uint256 _request,  string memory _uri ) public onlyEcosystem {
        require ( !Requests[_request]._completed , "Already processed");
        Requests[_request]._completed = true;
        nameChangeRequestNumberProcessed++;
        warbotmanufacturer.setTokenURIEngine ( Requests[_request]._tokenid, _uri ); 
   }
   

     
    
    
    
    
    function emergencyWithdrawal () public onlyOwner {
        ERC20 _erc20 = ERC20 ( ecosystem.returnAddress("Minikishu") );
        uint256 _balance = _erc20.balanceOf( address(this));
        _erc20.transfer ( msg.sender , _balance );
    }
    
    modifier onlyEcosystem() {
        EcosystemContract _engine = EcosystemContract ( ecosystemaddress );
        require ( _engine.isEngineContract(msg.sender), "Not an Engine Contract");
         _;
    }
    
    modifier OnlyEmergency() {
        require( msg.sender == EmergencyAddress, "Emergency Only");
        _;
    }
    
}