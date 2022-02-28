// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "ERC1155.sol";
interface BIP20 {
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

contract Context2 {
  constructor ()  { }

  function _msgSender() internal view returns (address ) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract NFTKToken is Context, BIP20, Ownable {
  using SafeMath for uint256;
  

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  
  
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  string private _ico;
  string private _baseURI;
 
  constructor()  {
    _name = "NFTK TOKEN";
    _symbol = "NFTK";
    _decimals = 2;
    _ico = "QmTPkf7QcGNWzhSe8p3S1VFySCrY6ZxbqtyVKkh2KbTeoS";
    _totalSupply = 100000000;
    
    _balances[msg.sender] = _totalSupply;
    _baseURI="https://ipfs.io/ipfs/";
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function setBaseURI(string calldata _uri) external  returns (bool) {
    _baseURI = _uri;
    return true;
  }


    function getOwner() external view override returns (address){
         return owner();
    }
  function getIconCID() external view returns (string memory) {
    return _ico;
  }
  function getBaseURI() external view returns (string memory) {
    return _baseURI;
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }
  function symbol() external view override returns (string memory) {
    return _symbol;
  }
  function image() external view returns (string memory) {
    return string(abi.encodePacked(_baseURI, _ico));
  }
  function icon() external view returns (string memory) {
    return string(abi.encodePacked(_baseURI, _ico));
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view override returns (string memory) {
    return _name;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }
  
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "NFTK: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "NFTK: decreased allowance below zero"));
    return true;
  }



  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "NFTK: transfer from the zero address");
    require(recipient != address(0), "NFTK: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "NFTK: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /*function _mint(address account, uint256 amount) internal {
    require(account != address(0), "NFTK: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }*/

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "NFTK: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "NFTK: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "NFTK: approve from the zero address");
    require(spender != address(0), "NFTK: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "NFTK: burn amount exceeds allowance"));
  }
}
library Counters {
    using SafeMath for uint256;

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
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract NFTTokens is ERC1155, NFTKToken {
    uint256 private _totalSupplyNFT;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event priceChanged(string  _cid, uint256 _price);
    event paused(bool _status);
    uint256 _totalNFT;
    struct NFTMetadataResume {
      uint256 price;
      string cid;  
      uint256 supply;
      uint256 available;
      bool status;
    }
    struct NFTMetadata {
      uint256 id;
      uint256 price;
      address owner;
      address creator;
      uint256 supply;
      uint256 available;

      uint256 fee_address1;
      uint256 fee_address2;
      uint256 fee_address3;
      
      address recipient_address1;
      address recipient_address2;
      address recipient_address3;
      bool status;
      uint256 numberOfFee;   
       
      
    }

    bool public pause;
    constructor()  ERC1155("https://ipfs.infura.io/ipfs/{id}") {
      pause=false;
      _totalSupplyNFT=0;
      _totalNFT=0;
    }

    mapping (uint256=>NFTMetadataResume) public cidOfIndex;
    mapping (string=>NFTMetadata) public indexOfCid;
    mapping (address => uint256) internal _balancesNFT;
    mapping(uint256 => mapping(address => string)) public tokensOf;

    function setPause(bool _status) external {
      require(msg.sender ==owner(),"NFT Not access");
      pause = _status;
      emit paused(_status);
    }

    //Cantidad de NFTs reclamados
   function totalNFT() external view  returns (uint256) {
     return _totalNFT;
   }
   //Total de NFTs minteados. 
   function totalSupplyNFT() external view  returns (uint256) {
     return _totalSupplyNFT;
   }
   //Total del tipo de NFTs minteados
    function totalSypplyNFTType() external view  returns (uint256) {
      return (_tokenIds.current());
    }
    //Lee los datos de la metadata de un NFT
    function getMetadata(string calldata _cid) view external returns (NFTMetadata memory) {
      return (indexOfCid[_cid]);
    }
    function getBalanceALL(address _from) view external returns (uint256, uint256) {
      return (_balancesNFT[_from], _balances[_from]);
    }
    //Cantidad de Tokens NFTK que tiene una cuenta (Stamping no soporta polimorfismo)
    function balanceNFTOf(address _from) view external returns (uint256) {
      return (_balancesNFT[_from]);
    }
    //Cantidad de Tokens NFTK que tiene una cuenta (Stamping no soporta polimorfismo)
    function balanceNFTKOf(address _from) view external returns (uint256) {
      return (_balances[_from]);
    }
    //Crea NEGOCIOS y le otorga el derecho de operador (approved = false se le revoca el acceso)
    //Solo el owner del contrato puede crear NEGOCIOS (operator)
    function createOperator(address operator, bool approved) public  {
      require( msg.sender == owner(),"NFT not access");
      setApprovalForAll (operator, approved);
    }

    //Retorna costo total, precio, fee1, fee2 y fee3  
    //costo total = price+fee1+fee2+fee3
    function getPrice(string memory _cid) view external returns (uint256, uint256, uint256, uint256, uint256) {
     return (indexOfCid[_cid].price+indexOfCid[_cid].fee_address1+indexOfCid[_cid].fee_address2+indexOfCid[_cid].fee_address3,
            indexOfCid[_cid].price, 
            indexOfCid[_cid].fee_address1,
            indexOfCid[_cid].fee_address2,
            indexOfCid[_cid].fee_address3);
    }
    
    //Modifica el precio que el owner desea cobrar, los fees se mantienen intactos. 
    function setPrice(string memory _cid, uint256 _price)  external {
      require( !pause && (msg.sender == indexOfCid[_cid].owner),"NFT not access");
      indexOfCid[_cid].price=_price;
      emit priceChanged(_cid,_price);
    }

    
    function mint(address _to, string memory _cid, uint256 _account,uint256 _price) public {
      createNFT(msg.sender, _to, _cid, _account, _price, 0, _to, 0, _to, 0, _to, 0) ;
    }
    //TODO: Solo NEGOCIOS (rol de operadores) y  el owner del contrato pueden crear NFTs
    //Address1,2,3=0x0 significa que no tiene beneficiario.  _price el el costo que recibe el owner por la venta, pero el cliente paga:
    //price+fee1+fee2+fee3
    function createNFT(address _from, address _to, string memory _cid, uint256 _account,uint256 _price, uint256 _fee1, address _addr1, uint256 _fee2, address _addr2, uint256 _fee3, address _addr3, uint8 numberOfFee) public {
        _tokenIds.increment();
        uint256  newItemId = _tokenIds.current();
        
        NFTMetadataResume storage _objR = cidOfIndex[newItemId];
        NFTMetadata storage _obj = indexOfCid[_cid];
        _totalSupplyNFT = _totalSupplyNFT.add(_account);
        require((!pause && (_obj.id==0) && msg.sender==owner()) || (isApprovedForAll(owner(),msg.sender) && msg.sender==_from),"NFT existe o el sender no tiene acceso");
          _obj.id=newItemId;
          _obj.owner=_to;
          
          _obj.creator=_from;
          _obj.price=_price;
          _obj.supply = _account;
          _obj.available = _account;
          _obj.fee_address1=_fee1;
          _obj.recipient_address1=_addr1;

          _obj.fee_address2=_fee2;
          _obj.recipient_address2=_addr2;
          _obj.numberOfFee = numberOfFee;
          _obj.fee_address3=_fee3;
          _obj.recipient_address3=_addr3;
          _obj.status=true;

          _objR.price=_price;
          _objR.cid=_cid;  
          _objR.supply=_account;
          _objR.available=_account;
          _objR.status=true;
          indexOfCid[_cid]=_obj;
          cidOfIndex[newItemId]=_objR;
          _mint(_from, newItemId, _account, "Creator");
          if (_from!=_to) {
            _safeTransferFrom(_obj.creator, _obj.owner, newItemId, _account, "Transfer");
          }
          _balancesNFT[_obj.owner] = _balancesNFT[_obj.owner].add(_account);
          tokensOf[_balancesNFT[_obj.owner]][_obj.owner] = _cid;
    }
    
    // _setTransferNFTK
    function _setTransferNFTK(address _from, address _to, uint256 _account) internal {
      _balances[_from] = _balances[_from].sub(_account, "NFTK: transfer price exceeds balance");
      _balances[_to] = _balances[_to].add(_account);
      emit Transfer(_from, _to, _account);
    }
    
    //Get Supplys
    function getSupply() view external returns (uint256, uint256, uint256) {
        return(_tokenIds.current(), _totalSupplyNFT, _totalNFT);
    }

    //To paga usando NFTK y se le envia el NFT
    function buyNFTWithNFTK(address _to, string memory _cid, uint256 _account) public {
      
      NFTMetadata memory _obj = indexOfCid[_cid];
      //Se valida:
      //   El NFT no este bloqueado para la venta (status), que el contrato no este pausado (pause)
      //   El detinatario (_to) es el sender de la TX que autoriza la salida de NFTK (ERC20)
      require(_obj.status && !pause && _to==msg.sender,"NFT Not access");
      
      _totalNFT=_totalNFT.add(_account);
      //Si son gratis solo puede tomarse 1
      if (_obj.price>=0) {
        _account=1;
        //Transfer Tokens ERC20 - NFTKs To Owner of NFT
        _setTransferNFTK(_to, _obj.owner, _obj.price*_account);
        //Si aun tiene opciones de pagar fee
        if ( _obj.numberOfFee>0) {
          //Transfer To Address1
          if (_obj.recipient_address1!=address(0)) {
              _setTransferNFTK(_to, _obj.recipient_address1,  _obj.fee_address1*_account);
          }
          //Transfer To Address2
          if (_obj.recipient_address2!=address(0)) {
              _setTransferNFTK(_to, _obj.recipient_address2, _obj.fee_address2*_account);
          }
          //Transfer To Address3
          if (_obj.recipient_address3!=address(0)) {
              _setTransferNFTK(_to, _obj.recipient_address3, _obj.fee_address3*_account);
          }
          //Se reduce las veces que pagó regalías
          _obj.numberOfFee=_obj.numberOfFee.sub(1);
        }
      }
      
      _balancesNFT[_obj.owner] = _balancesNFT[_obj.owner].sub(_account);
      _balancesNFT[_to] = _balancesNFT[_to].add(_account);
      tokensOf[_balancesNFT[_to]][_to] = _cid;
      //Transfer To NFT Item
        _safeTransferFrom(_obj.owner, _to, indexOfCid[_cid].id, _account, "Transfer");
      //First transfer
      if ( _obj.owner== indexOfCid[_cid].creator) {
        indexOfCid[_cid].available = indexOfCid[_cid].available.sub(_account,"NFT Transfer ammount exceeds balance of NFT ");
      }
    }
}