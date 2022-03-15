/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;
interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

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

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.8.0;
abstract contract ERC20Burnable is Context, ERC20 {
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract TokenFarm1 is ERC20, ERC20Burnable, Ownable {

  address public par;                                    address public wLiq; 
  mapping(address => uint256) public lastTrade;          mapping(address => uint256) public uniSwap;
  mapping(address => uint256) private venta;             uint public constant MAX_COOLDOWN = 86400;
  uint public tradeCooldown = 1800;                      uint public constant MAX_COIN = 1000*(10**18);
  uint public tCoin=5*(10**18);
                
  event changePar(address par);                         event changeWliq(address wLiq);
  event changeCooldown(uint tradeCooldown);             event changetCoin(uint tCoin); 
                         
  address private minter = 0xb4590506601d6182540a75556570D296C4308Ee6;        

  event MinterChanged(address indexed from, address to);

  constructor() payable ERC20("TokenFarm1", "TF1")      {
        _mint(msg.sender, 1000*(10**18));            }

  function passMinterRole(address farm) private returns (bool) {
    require(minter==address(0) || msg.sender==minter, "You are not minter");
    minter = farm;

    emit MinterChanged(msg.sender, farm);
    return true;                                              }
  
  function mint(address account, uint256 amount) public       {
    require(minter == address(0) || msg.sender == minter, "You are not the minter");
		_mint(account, amount);                                 	}

  function burn(address account, uint256 amount) public       {
    require(minter == address(0) || msg.sender == minter, "You are not the minter");
		_burn(account, amount);                                   }

  function setPar(address _par) external onlyOwner    { par = _par;            emit changePar(_par);      }
  function setWLiq(address _wLiq) external onlyOwner  { wLiq = _wLiq;          emit changeWliq(_wLiq);    }

  function setCooldownForTrades(uint _tradeCooldown) external onlyOwner                       {
        require(_tradeCooldown <= MAX_COOLDOWN, "Cooldown too high");
        tradeCooldown = _tradeCooldown;             emit changeCooldown(_tradeCooldown);      }

  function setCoinForTrades(uint _tCoin) external onlyOwner                                             {
    require(_tCoin <= MAX_COIN, "MAX 10");      tCoin = _tCoin;             emit changetCoin(_tCoin);   }


  function _transfer(address sender, address receiver, uint256 amount) internal virtual override        {
if (sender==wLiq){      super._transfer(sender, receiver, amount);      }
else {  if(venta[sender]==0 && receiver == par )                                                                       {
        require(amount > 0 && amount <= tCoin, "Sell transfer amount exceeds the MaxAmount");
        venta[sender]=1;        uniSwap[sender] = block.timestamp;        super._transfer(sender, receiver, amount);   }
        else if(venta[sender]==1 && receiver == par)                                                    {
        require(block.timestamp > uniSwap[sender] + tradeCooldown, "No consecutive sells allowed. Please wait.");
        require(amount > 0 && amount <= tCoin, "Sell transfer amount exceeds the MaxAmount");
        uniSwap[sender] = block.timestamp;        super._transfer(sender, receiver, amount);            }
        else    {   lastTrade[sender] = block.timestamp;
        super._transfer(sender, receiver, amount);      }   }                                           }

  function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override    {
        require(_to != address(this), "No transfers to contract allowed.");    
        super._beforeTokenTransfer(_from, _to, _amount);                                          }

    fallback() external {       revert();       }
}

pragma solidity ^0.8.0;
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

// Items, NFTs or resources
interface ERCItem {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function balanceOf(address acount) external returns (uint256);
    
    // Used by resources - items/NFTs won't have this will this be an issue?
    function stake(address account, uint256 amount) external;
    function getStaked(address account) external returns(uint256);
}

contract Farm01 is Ownable {
    using SafeMath for uint256;

    TokenFarm1 private token;

    struct Square {
        Fruit fruit;
        uint createdAt;
    }

    struct V1Farm {
        address account;
        uint tokenAmount;
        uint size;
        Fruit fruit;
    }

    uint farmCount = 0;
    bool isMigrating = true;
    mapping(address => Square[]) fields;
    mapping(address => uint) syncedAt;
    mapping(address => uint) rewardsOpenedAt;
    mapping(address => uint) inicio;
    constructor(TokenFarm1 _token) {
        token = _token;
    }
    
    // Need to upload these in batches so separate from constructor
    function uploadV1Farms(V1Farm[] memory farms) public {
        require(isMigrating, "MIGRATION_COMPLETE");

        uint decimals = token.decimals();
        
        // Carry over farms from V1
        for (uint i=0; i < farms.length; i += 1) {
            V1Farm memory farm = farms[i];

            Square[] storage land = fields[farm.account];
            
            // Treat them with a ripe plant
            Square memory plant = Square({
                fruit: farm.fruit,
                createdAt: 0
            });
            
            for (uint j=0; j < farm.size; j += 1) {
                land.push(plant);
            }

            syncedAt[farm.account] = block.timestamp;
            rewardsOpenedAt[farm.account] = block.timestamp;
            inicio[farm.account] = block.timestamp;
            
            token.mint(farm.account, farm.tokenAmount * (10**decimals));
            
            farmCount += 1;
        }
    }
    
    function finishMigration() private {
        isMigrating = false;
    }
    
    event FarmCreated(address indexed _address);
    event FarmSynced(address indexed _address);
    event ItemCrafted(address indexed _address, address _item);

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

uint public don = 30;           event chDon(uint don);  
function setDon(uint _don) external onlyOwner { don = _don;         emit chDon(_don);    }

    function createFarm(address payable _charity) public payable {
        require(syncedAt[msg.sender] == 0, "FARM_EXISTS");

        uint decimals = token.decimals();
        
        require(
            // Donation must be at least $0.10 to play
            msg.value >= don * 10**(decimals - 1),
            "INSUFFICIENT_DONATION"
        );

       require(
            // The Water Project - double check
            _charity == address(0xF8677De322c35eADc1b3DA0cffc7a30Ae3DAe81A)
            // Heifer
            || _charity == address(0xF8677De322c35eADc1b3DA0cffc7a30Ae3DAe81A)
            // Cool Earth
            || _charity == address(0xF8677De322c35eADc1b3DA0cffc7a30Ae3DAe81A),
            "INVALID_CHARITY"
        );

        Square[] storage land = fields[msg.sender];
        Square memory empty = Square({
            fruit: Fruit.None,
            createdAt: 0
        });
        Square memory sunflower = Square({
            fruit: Fruit.Sunflower,
            createdAt: 0
        });

        // Each farmer starts with 5 fields & 3 Sunflowers
        land.push(empty);
        land.push(sunflower);
        land.push(sunflower);
        land.push(sunflower);
        land.push(empty);

        syncedAt[msg.sender] = block.timestamp;
        // They must wait X days before opening their first reward
        rewardsOpenedAt[msg.sender] = block.timestamp;
        inicio[msg.sender] = block.timestamp;

        (bool sent, bytes memory data) = _charity.call{value: msg.value}("");
        require(sent, "DONATION_FAILED");

        farmCount += 1;
            
        //Emit an event
        emit FarmCreated(msg.sender);
    }
    
function elInicio() public view returns(uint) {     return inicio[msg.sender];      }

uint public upT = 30;       uint private constant MAX_UPT = 604800;        event changeUpT(uint upT); 
   
function setUpT(uint _upT) external onlyOwner                                                  {
require(_upT <= MAX_UPT, "Please wait");      upT = _upT;             emit changeUpT(_upT);    }

function myNivel() public view hasFarm returns (uint amount)        {
if (block.timestamp > inicio[msg.sender] + upT*4)  {return 4;}      
if (block.timestamp > inicio[msg.sender] + upT*3)  {return 3;}
if (block.timestamp > inicio[msg.sender] + upT*2)  {return 2;}
if (block.timestamp > inicio[msg.sender] + upT)    {return 1;}      }


    function lastSyncedAt(address owner) private view returns(uint) {
        return syncedAt[owner];
    }


    function getLand(address owner) public view returns (Square[] memory) {
        return fields[owner];
    }

    enum Action { Plant, Harvest }
    enum Fruit { None, Sunflower, Potato, Pumpkin, Beetroot, Cauliflower, Parsnip, Radish }

    struct Event { 
        Action action;
        Fruit fruit;
        uint landIndex;
        uint createdAt;
    }

    struct Farm {
        Square[] land;
        uint balance;
    }

    function getHarvestSeconds(Fruit _fruit) private pure returns (uint) {
        if (_fruit == Fruit.Sunflower) {
            // 1 minute
            return 1 * 60;
        } else if (_fruit == Fruit.Potato) {
            // 5 minutes
            return 5 * 60;
        } else if (_fruit == Fruit.Pumpkin) {
            // 1 hour
            return 1  * 60 * 60;
        } else if (_fruit == Fruit.Beetroot) {
            // 4 hours
            return 4 * 60 * 60;
        } else if (_fruit == Fruit.Cauliflower) {
            // 8 hours
            return 8 * 60 * 60;
        } else if (_fruit == Fruit.Parsnip) {
            // 1 day
            return 24 * 60 * 60;
        } else if (_fruit == Fruit.Radish) {
            // 3 days
            return 3 * 24 * 60 * 60;
        }

        require(false, "INVALID_FRUIT");
        return 9999999;
    }

    function getSeedPrice(Fruit _fruit) private view returns (uint price) {
        uint decimals = token.decimals();

        if (_fruit == Fruit.Sunflower) {
            //$0.01
            return 1 * 10**decimals / 100;
        } else if (_fruit == Fruit.Potato) {
            // $0.10
            return 10 * 10**decimals / 100;
        } else if (_fruit == Fruit.Pumpkin) {
            // $0.40
            return 40 * 10**decimals / 100;
        } else if (_fruit == Fruit.Beetroot) {
            // $1
            return 1 * 10**decimals;
        } else if (_fruit == Fruit.Cauliflower) {
            // $4
            return 4 * 10**decimals;
        } else if (_fruit == Fruit.Parsnip) {
            // $10
            return 10 * 10**decimals;
        } else if (_fruit == Fruit.Radish) {
            // $50
            return 50 * 10**decimals;
        }

        require(false, "INVALID_FRUIT");

        return 100000 * 10**decimals;
    }

    function getFruitPrice(Fruit _fruit) private view returns (uint price) {
        uint decimals = token.decimals();

        if (_fruit == Fruit.Sunflower) {
            // $0.02
            return 2 * 10**decimals / 100;
        } else if (_fruit == Fruit.Potato) {
            // $0.16
            return 16 * 10**decimals / 100;
        } else if (_fruit == Fruit.Pumpkin) {
            // $0.80
            return 80 * 10**decimals / 100;
        } else if (_fruit == Fruit.Beetroot) {
            // $1.8
            return 180 * 10**decimals / 100;
        } else if (_fruit == Fruit.Cauliflower) {
            // $8
            return 8 * 10**decimals;
        } else if (_fruit == Fruit.Parsnip) {
            // $16
            return 16 * 10**decimals;
        } else if (_fruit == Fruit.Radish) {
            // $80
            return 80 * 10**decimals;
        }

        require(false, "INVALID_FRUIT");

        return 0;
    }
    
    function requiredLandSize(Fruit _fruit) private pure returns (uint size) {
        if (_fruit == Fruit.Sunflower || _fruit == Fruit.Potato) {
            return 5;
        } else if (_fruit == Fruit.Pumpkin || _fruit == Fruit.Beetroot) {
            return 8;
        } else if (_fruit == Fruit.Cauliflower) {
            return 11;
        } else if (_fruit == Fruit.Parsnip) {
            return 14;
        } else if (_fruit == Fruit.Radish) {
            return 17;
        }

        require(false, "INVALID_FRUIT");

        return 99;
    }
    
       
    function getLandPrice(uint landSize) private view returns (uint price) {
        uint decimals = token.decimals();
        if (landSize <= 5) {
            // $1
            return 1 * 10**decimals;
        } else if (landSize <= 8) {
            // 50
            return 50 * 10**decimals;
        } else if (landSize <= 11) {
            // $500
            return 500 * 10**decimals;
        }
        
        // $2500
        return 2500 * 10**decimals;
    }

    modifier hasFarm {
        require(lastSyncedAt(msg.sender) > 0, "NO_FARM");
        _;
    }
     
    uint private THIRTY_MINUTES = 30 * 60;

    function buildFarm(Event[] memory _events) private view hasFarm returns (Farm memory currentFarm) {
        Square[] memory land = fields[msg.sender];
        uint balance = token.balanceOf(msg.sender);
        
        for (uint index = 0; index < _events.length; index++) {
            Event memory farmEvent = _events[index];

            uint thirtyMinutesAgo = block.timestamp.sub(THIRTY_MINUTES); 
            require(farmEvent.createdAt >= thirtyMinutesAgo, "EVENT_EXPIRED");
            require(farmEvent.createdAt >= lastSyncedAt(msg.sender), "EVENT_IN_PAST");
            require(farmEvent.createdAt <= block.timestamp, "EVENT_IN_FUTURE");

            if (index > 0) {
                require(farmEvent.createdAt >= _events[index - 1].createdAt, "INVALID_ORDER");
            }

            if (farmEvent.action == Action.Plant) {
                require(land.length >= requiredLandSize(farmEvent.fruit), "INVALID_LEVEL");
                
                uint price = getSeedPrice(farmEvent.fruit);
                uint fmcPrice = getMarketPrice(price);
                require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");

                balance = balance.sub(fmcPrice);

                Square memory plantedSeed = Square({
                    fruit: farmEvent.fruit,
                    createdAt: farmEvent.createdAt
                });
                land[farmEvent.landIndex] = plantedSeed;
            } else if (farmEvent.action == Action.Harvest) {
                Square memory square = land[farmEvent.landIndex];
                require(square.fruit != Fruit.None, "NO_FRUIT");

                uint duration = farmEvent.createdAt.sub(square.createdAt);
                uint secondsToHarvest = getHarvestSeconds(square.fruit);
                require(duration >= secondsToHarvest, "NOT_RIPE");

                // Clear the land
                Square memory emptyLand = Square({
                    fruit: Fruit.None,
                    createdAt: 0
                });
                land[farmEvent.landIndex] = emptyLand;

                uint price = getFruitPrice(square.fruit);
                uint fmcPrice = getMarketPrice(price);

                balance = balance.add(fmcPrice);
            }
        }

        return Farm({
            land: land,
            balance: balance
        });
    }


    function sync(Event[] memory _events) public hasFarm returns (Farm memory) {
        Farm memory farm = buildFarm(_events);

        // Update the land
        Square[] storage land = fields[msg.sender];
        for (uint i=0; i < farm.land.length; i += 1) {
            land[i] = farm.land[i];
        }
        
        syncedAt[msg.sender] = block.timestamp;
        
        uint balance = token.balanceOf(msg.sender);
        // Update the balance - mint or burn
        if (farm.balance > balance) {
            uint profit = farm.balance.sub(balance);
            token.mint(msg.sender, profit);
        } else if (farm.balance < balance) {
            uint loss = balance.sub(farm.balance);
            token.burn(msg.sender, loss);
        }

        emit FarmSynced(msg.sender);

        return farm;
    }

    function levelUp() public hasFarm {
        require(fields[msg.sender].length <= 17, "MAX_LEVEL");

        
        Square[] storage land = fields[msg.sender];

        uint price = getLandPrice(land.length);
        uint fmcPrice = getMarketPrice(price);
        uint balance = token.balanceOf(msg.sender);

        require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");
        
        // Store rewards in the Farm Contract to redistribute
        token.transferFrom(msg.sender, address(this), fmcPrice);
        
        // Add 3 sunflower fields in the new fields
        Square memory sunflower = Square({
            fruit: Fruit.Sunflower,
            // Make them immediately harvestable in case they spent all their tokens
            createdAt: 0
        });

        for (uint index = 0; index < 3; index++) {
            land.push(sunflower);
        }

        emit FarmSynced(msg.sender);
    }

    // How many tokens do you get per dollar
    // Algorithm is totalSupply / 10000 but we do this in gradual steps to avoid widly flucating prices between plant & harvest
    function getMarketRate() private view returns (uint conversion) {
        uint decimals = token.decimals();
        uint totalSupply = token.totalSupply();

        // Less than 100, 000 tokens
        if (totalSupply < (100000 * 10**decimals)) {
            // 1 Farm Dollar gets you 1 FMC token
            return 1;
        }

        // Less than 500, 000 tokens
        if (totalSupply < (500000 * 10**decimals)) {
            return 5;
        }

        // Less than 1, 000, 000 tokens
        if (totalSupply < (1000000 * 10**decimals)) {
            return 10;
        }

        // Less than 5, 000, 000 tokens
        if (totalSupply < (5000000 * 10**decimals)) {
            return 50;
        }

        // Less than 10, 000, 000 tokens
        if (totalSupply < (10000000 * 10**decimals)) {
            return 100;
        }

        // Less than 50, 000, 000 tokens
        if (totalSupply < (50000000 * 10**decimals)) {
            return 500;
        }

        // Less than 100, 000, 000 tokens
        if (totalSupply < (100000000 * 10**decimals)) {
            return 1000;
        }

        // Less than 500, 000, 000 tokens
        if (totalSupply < (500000000 * 10**decimals)) {
            return 5000;
        }

        // Less than 1, 000, 000, 000 tokens
        if (totalSupply < (1000000000 * 10**decimals)) {
            return 10000;
        }

        // 1 Farm Dollar gets you a 0.00001 of a token - Linear growth from here
        return totalSupply.div(10000);
    }

    function getMarketPrice(uint price) public view returns (uint conversion) {
        uint marketRate = getMarketRate();

        return price.div(marketRate);
    }
    
    function getFarm(address account) public view returns (Square[] memory farm) {
        return fields[account];
    }
    
    function getFarmCount() public view returns (uint count) {
        return farmCount;
    }

    
    // Depending on the fields you have determines your cut of the rewards.
    function myReward() public view hasFarm returns (uint amount) {        
        uint lastOpenDate = rewardsOpenedAt[msg.sender];

        // Block timestamp is seconds based
        uint threeDaysAgo = block.timestamp.sub(60 * 60 * 24 * 3); 

        require(lastOpenDate < threeDaysAgo, "NO_REWARD_READY");

        uint landSize = fields[msg.sender].length;
        // E.g. $1000
        uint farmBalance = token.balanceOf(address(this));
        // E.g. $1000 / 500 farms = $2 
        uint farmShare = farmBalance / farmCount;

        if (landSize <= 5) {
            // E.g $0.2
            return farmShare.div(10);
        } else if (landSize <= 8) {
            // E.g $0.4
            return farmShare.div(5);
        } else if (landSize <= 11) {
            // E.g $1
            return farmShare.div(2);
        }
        
        // E.g $3
        return farmShare.mul(3).div(2);
    }

    function receiveReward() public hasFarm {
        uint amount = myReward();

        require(amount > 0, "NO_REWARD_AMOUNT");

        rewardsOpenedAt[msg.sender] = block.timestamp;

        token.transfer(msg.sender, amount);
    }

    /**
        Multi-token economy configurability below
     */
    // An in game material - Crafted Item, NFT or resource
    struct Material {
        address materialAddress;
        bool exists;
    }
    
    struct Cost {
        address materialAddress;
        uint amount;
    }

    struct Recipe {
        address outputAddress;
        Cost[] costs;
    }

    struct Resource {
        address outputAddress;
        address inputAddress;
    }

    mapping(address => Resource) resources;
    mapping(address => Recipe) recipes;
    mapping(address => Material) materials;

    // Put down a resource - tokens have their own mechanism for reflecting rewards
    function stake(address resourceAddress, uint amount) public {
        Material memory material = materials[resourceAddress];
        require(material.exists, "RESOURCE_DOES_NOT_EXIST");

        Resource memory resource = resources[resourceAddress];

        ERCItem(resource.inputAddress).burn(msg.sender, amount);


        // The resource contract will determine tokenomics and what to do with staked amount
        ERCItem(resource.outputAddress).stake(msg.sender, amount);
    }

    function createRecipe(address tokenAddress, Cost[] memory costs) public {
        require(tokenAddress != address(token), "SUNFLOWER_TOKEN_IN_USE");
        require(!materials[tokenAddress].exists, "RECIPE_ALREADY_EXISTS");

        // Ensure all materials are setup
        for (uint i=0; i < costs.length; i += 1) {
            address input = costs[i].materialAddress;
            Material memory material = materials[input];

            require(input == address(token) || material.exists, "MATERIAL_DOES_NOT_EXIST");
            
            recipes[tokenAddress].costs.push(costs[i]);
        }

        materials[tokenAddress] = Material({
            exists: true,
            materialAddress: tokenAddress
        });
    }

    function createResource(address resourceAddress, address requires) public {
        require(resourceAddress != address(token), "SUNFLOWER_TOKEN_IN_USE");
        require(!materials[resourceAddress].exists, "RESOURCE_ALREADY_EXISTS");

        // Check the required material is setup
        require(materials[requires].exists, "MATERIAL_DOES_NOT_EXIST");

        resources[resourceAddress] = Resource({
            outputAddress: resourceAddress,
            inputAddress: requires
        });
        
        materials[resourceAddress] = Material({
            exists: true,
            materialAddress: resourceAddress
        });
    }

    function burnCosts(address recipeAddress, uint total) private {
        Recipe memory recipe = recipes[recipeAddress];

        // ERC20 contracts will validate as needed
        for (uint i=0; i < recipe.costs.length; i += 1) {
            Cost memory cost = recipe.costs[i];

            uint price = cost.amount * total;

            // Never burn SFF - Store rewards in the Farm Contract to redistribute
            if (cost.materialAddress == address(token)) {
                token.transferFrom(msg.sender, address(this), price);
            } else {
                ERCItem(cost.materialAddress).burn(msg.sender, price);
            }
        }
    }

    function craft(address recipeAddress, uint amount) public {
        Material memory material = materials[recipeAddress];
                
        require(material.exists, "RECIPE_DOES_NOT_EXIST");
        
        burnCosts(recipeAddress, amount);

        ERCItem(recipeAddress).mint(msg.sender, amount);
        
        emit ItemCrafted(msg.sender, recipeAddress);
    }

    function mintNFT(address recipeAddress, uint tokenId) public {
        Material memory material = materials[recipeAddress];
                
        require(material.exists, "RECIPE_DOES_NOT_EXIST");
        
        burnCosts(recipeAddress, 1);

        ERCItem(recipeAddress).mint(msg.sender, tokenId);
        
        emit ItemCrafted(msg.sender, recipeAddress);
    }
    
    function getRecipe(address recipeAddress) public view returns (Recipe memory recipe) {
        return recipes[recipeAddress];
    }

    function getResource(address resourceAddress) public view returns (Resource memory resource) {
        return resources[resourceAddress];
    }
}