// /**
//  *Submitted for verification at Etherscan.io on 2023-04-19
//  */

// // SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity ^0.8.7;

// interface ERC20 {
//     function totalSupply() external view returns (uint);

//     function balanceOf(address) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);

//     function transfer(address, uint) external returns (bool);

//     function transferFrom(address, address, uint) external returns (bool);

//     function mint(address, uint) external;

//     function minter() external returns (address);

//     function claim(address, uint) external returns (bool);

//     function updateTokenURI(string memory) external;

// }

// contract TOKEN is ERC20 {
//     string public name;
//     string public symbol;
//     uint8 public constant decimals = 18;
//     uint public totalSupply;
//     string public tokenURI;
//     uint public taxFee = 5; // 5% taxFee
//     address public marketingWallet = 0xE332a57Bbe97Bfc0D00BAc8CbC404091175Dab87;

//     mapping(address => uint) public balanceOf;

//     mapping(address => uint256) private balances;
//     mapping(address => mapping(address => uint)) public allowance;

//     bool public initialMinted;
//     address public minter;
//     address public burner;
//     address public redemptionReceiver;
//     address public merkleClaim;

//     event Transfer(address indexed from, address indexed to, uint value);
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Burn(address indexed from, uint256 value);

//     constructor(
//         string memory _name,
//         string memory _symbol,
//         uint _totalSupply,
//         string memory _tokenURI
//     ) {
//         minter = msg.sender;
//         burner = msg.sender;
//         name = _name;
//         symbol = _symbol;
//         tokenURI = _tokenURI;
//         totalSupply = _totalSupply;
//         balances[msg.sender] = _totalSupply;
//     }

//     modifier onlyOwner() {
//         msg.sender == minter;
//         msg.sender == burner;
//         _;
//     }

//     // Function to update the token URI
//     function updateTokenURI(string memory _newTokenURI) public onlyOwner{
//         tokenURI = _newTokenURI;
//     }

//     // No checks as its meant to be once off to set minting rights to BaseV1 Minter
//     function setMinter(address _minter) external onlyOwner {
//         require(msg.sender == minter);
//         minter = _minter;
//     }

//     function setRedemptionReceiver(address _receiver) external {
//         require(msg.sender == minter);
//         redemptionReceiver = _receiver;
//     }

//     function setMerkleClaim(address _merkleClaim) external {
//         require(msg.sender == minter);
//         merkleClaim = _merkleClaim;
//     }

//     // Initial mint: total 5M
//     function initialMint(address _recipient) external onlyOwner {
//         require(msg.sender == minter && !initialMinted);
//         initialMinted = true;
//         _mint(_recipient, 5_000_000 * 1e18);
//     }

//     function approve(address _spender, uint _value) external returns (bool) {
//         allowance[msg.sender][_spender] = _value;
//         emit Approval(msg.sender, _spender, _value);
//         return true;
//     }

//     function _mint(address _to, uint _amount) internal returns (bool) {
//         totalSupply += _amount;
//         unchecked {
//             balanceOf[_to] += _amount;
//         }
//         emit Transfer(address(0x0), _to, _amount);
//         return true;
//     }

//     function _burn(address _from, uint _amount) internal returns (bool) {
//         totalSupply -= _amount;
//         unchecked {
//             balanceOf[_from] -= _amount;
//         }
//         emit Transfer(_from, address(0), _amount);
//         return true;
//     }

//     function _transfer(
//         address _from,
//         address _to,
//         uint _value
//     ) internal returns (bool) {
//         balanceOf[_from] -= _value;
//         unchecked {
//             balanceOf[_to] += _value;
//         }
//         emit Transfer(_from, _to, _value);
//         return true;
//     }

//     function transfer(address _to, uint _value) external returns (bool) {
//         uint taxAmount = _value * taxFee / 100;
//         uint transferAmount = _value - taxAmount;

//         balanceOf[marketingWallet] += taxAmount;
//         return _transfer(msg.sender, _to, transferAmount);
//     }

//     function transferFrom(
//         address _from,
//         address _to,
//         uint _value
//     ) external returns (bool) {
//         uint taxAmount = _value * taxFee / 100;
//         uint transferAmount = _value - taxAmount;

//         uint allowed_from = allowance[_from][msg.sender];
//         if (allowed_from != type(uint).max) {
//             allowance[_from][msg.sender] -= _value;
//         }
//         balanceOf[marketingWallet] += taxAmount;
//         return _transfer(_from, _to, transferAmount);
//     }

//     function mint(address account, uint amount) public onlyOwner {
//         require(msg.sender == minter);
//         _mint(account, amount);
//     }

//     function burnFrom(address from, uint amount) public onlyOwner {
//         require(amount > 0, "Amount must be greater than zero (0)");
//         require(balanceOf[msg.sender] > amount, "Insufficient Amount");
//         require(balanceOf[from] >= amount, "Insufficient Amount");
//         require(msg.sender == burner);
//         _burn(from, amount);
//     }

//     function claim(address account, uint amount) external returns (bool) {
//         require(msg.sender == redemptionReceiver || msg.sender == merkleClaim);
//         _mint(account, amount);
//         return true;
//     }

//     function burn(uint256 _amount) public {
//         require(balances[msg.sender] >= _amount, "Insufficient balance");

//         balances[msg.sender] -= _amount;
//         totalSupply -= _amount;

//         emit Transfer(msg.sender, address(0), _amount);
//         emit Burn(msg.sender, _amount);
//     }

//     function _balanceOf(address _address) public view returns (uint256) {
//         return balances[_address];
//     }

//     function updateTaxFee(uint setFee) external onlyOwner {
//         require(msg.sender == minter);
//         taxFee = setFee;
//     }

//     function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
//         require(msg.sender == minter);
//        // balance.marketingWallet = balance.newMarketingWallet;
//         marketingWallet = newMarketingWallet;
//     }
// }

pragma solidity ^0.8.7;

interface erc20 {
    function totalSupply() external view returns (uint);

    //function balanceOf(address) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);

    function mint(address, uint) external;

    function minter() external returns (address);

    function claim(address, uint) external returns (bool);

    function updateTokenURI(string memory) external;
}

contract BUZIDEA is erc20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint public totalSupply;
    string public tokenURI;
    uint public taxFee = 5; // 5% taxFee
    address public marketingWallet = 0xE332a57Bbe97Bfc0D00BAc8CbC404091175Dab87;

    mapping(address => uint) public balanceOf;

    mapping(address => mapping(address => uint)) public allowance;

    bool public initialMinted;
    address public minter;
    address public burner;
    address public redemptionReceiver;
    address public merkleClaim;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        string memory _tokenURI
    ) {
        minter = msg.sender;
        burner = msg.sender;
        name = _name;
        symbol = _symbol;
        tokenURI = _tokenURI;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    modifier onlyOwner() {
        msg.sender == minter;
        msg.sender == burner;
        _;
    }

    // Function to update the token URI
    function updateTokenURI(string memory _newTokenURI) public onlyOwner {
        tokenURI = _newTokenURI;
    }

    // No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external onlyOwner {
        require(msg.sender == minter);
        minter = _minter;
    }

    function setRedemptionReceiver(address _receiver) external {
        require(msg.sender == minter);
        redemptionReceiver = _receiver;
    }

    function setMerkleClaim(address _merkleClaim) external {
        require(msg.sender == minter);
        merkleClaim = _merkleClaim;
    }

    // Initial mint: total 5M
    function initialMint(address _recipient) external onlyOwner {
        require(msg.sender == minter && !initialMinted);
        initialMinted = true;
        _mint(_recipient, 5_000_000 * 1e18);
    }

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint _amount) internal returns (bool) {
        totalSupply += _amount;
        unchecked {
            balanceOf[_to] += _amount;
        }
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _burn(address _from, uint _amount) internal returns (bool) {
        totalSupply -= _amount;
        unchecked {
            balanceOf[_from] -= _amount;
        }
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint _value
    ) internal returns (bool) {
        require(_value <= balanceOf[_from]);
        balanceOf[_from] -= _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external returns (bool) {
        require(_value <= balanceOf[msg.sender], "Insufficient Balance");
        uint taxAmount = (_value * taxFee) / 100;
        uint transferAmount = _value - taxAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[marketingWallet] += taxAmount;
        // _transfer(msg.sender, _to, transferAmount);
        //Transfer(address indexed from, address indexed to, uint value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, marketingWallet, taxAmount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool) {
        require(_value <= balanceOf[_from]);
        uint taxAmount = (_value * taxFee) / 100;
        uint transferAmount = _value - taxAmount;

        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        balanceOf[marketingWallet] += taxAmount;
        return _transfer(_from, _to, transferAmount);
    }

    function mint(address account, uint amount) public onlyOwner {
        require(msg.sender == minter, "Caller  is not minter!!!!!");
        _mint(account, amount);
    }

    function burnFrom(address from, uint amount) public onlyOwner {
        require(amount <= balanceOf[from]);
        require(amount > 0, "Amount must be greater than zero (0)");
        require(balanceOf[msg.sender] >= amount, "Insufficient Amount");
        require(balanceOf[from] >= amount, "Insufficient Amount");
        require(msg.sender == burner, "Caller is not burner !!!!!!!");
        _burn(from, amount);
    }

    function claim(address account, uint amount) external returns (bool) {
        require(msg.sender == redemptionReceiver || msg.sender == merkleClaim);
        _mint(account, amount);
        return true;
    }

    function burn(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;

        emit Transfer(msg.sender, address(0), _amount);
        emit Burn(msg.sender, _amount);
    }

    function updateTaxFee(uint setFee) external onlyOwner {
        require(msg.sender == minter, "Caller is not Autorized!!!!");
        taxFee = setFee;
    }

    function updateMarketingWallet(
        address newMarketingWallet
    ) external onlyOwner {
        require(msg.sender == minter, "Caller is not Autorized!!!!");
        // balance.marketingWallet = balance.newMarketingWallet;
        marketingWallet = newMarketingWallet;
    }
}