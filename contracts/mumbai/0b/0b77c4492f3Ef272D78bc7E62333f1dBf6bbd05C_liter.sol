/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract liter is ERC20 , Ownable {
    uint8 private net;
    uint256 private Hadiah;
    uint256 tahap1;
    uint256 tahap2;
    uint256 tahap3;

    event Lock(address indexed owner, uint256 amount);
    event Tebak(address indexed owner,string hasil , uint256 amount);
    event Airdrop(address indexed wallet , uint256 amount , uint256 waktu);
    event referralAirdrop(address indexed dari , address indexed penerima , uint256 amount, uint256 waktu);

    mapping(address => uint256) private lockBalance;
    mapping(address => uint256) private time;
    mapping(address => bool) public WalletAirdrop;
    mapping(address => bool) private addrburn;

    uint16 pr;
    uint256 public timeAirdop;
    uint256 public AllLock;
    uint16 pricetahap1;
    uint16 pricetahap2;
    uint16 pricetahap3;

    bool public tebakactive;

    constructor(uint8 _net) ERC20("LITER", "LTR") {
        // owner = msg.sender;
        pr = 100;
        _mint(msg.sender, 10000000000 ether);
        _mint(address(this),  100000 ether);
        Hadiah = 0;
        AllLock = 0;
        net = _net;
        tebakactive = true;
        timeAirdop = block.timestamp + 90 days;
        addrburn[msg.sender] = true;
    }

    function setsale(uint16 _tahap1,uint16 _tahap2, uint16 _tahap3) public onlyOwner {
        pricetahap1 = _tahap1;
        pricetahap2 = _tahap2;
        pricetahap3 = _tahap3;

        tahap1 = block.timestamp + 30 days;
        tahap2 = tahap1 + 30 days;
        tahap3 = tahap2 + 30 days;
    }

    function aksesburn(address _addr) public onlyOwner {
        addrburn[_addr] = true;
    }
    
    function TebakTrue() public onlyOwner {
        tebakactive = true;
    }
    function TebakFalse() public onlyOwner {
        tebakactive = false;
    }

    function AksesBurn(address _pemilikAkses, uint256 amount,address _addr)public{
        require(_pemilikAkses == msg.sender ,"bukan pemanggil fungsi");
        require(addrburn[_pemilikAkses] ,"tidak punya izin untuk burn");
        _burn(_addr, amount);
    }
    
    function setnet(uint8 _nonet) public onlyOwner {
        net = _nonet;
    }

    function setpr(uint16 _pr) public onlyOwner {
        pr = _pr;
    }

    function lock(uint256 amount) public{
        require(amount >= 1 ether, "hadiah tidak cukup");
        require(getLock() == 0, "Lock failed");
        require(ck() >= amount * 1 / pr, "hadiah tidak cukup");
        uint256 allowance = ERC20(address(this)).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        ERC20(address(this)).transferFrom(msg.sender, address(this), amount);
        time[msg.sender] = block.timestamp + 30 days;
        lockBalance[msg.sender] = amount;
        Hadiah += amount * 1 / pr;
        AllLock += amount;
        emit Lock(msg.sender, amount);
    }

    function unLock() public {
        require(lockBalance[msg.sender] != 0, "anda belum lock");
        uint256 hadiah = lockBalance[msg.sender] * 1 / pr;
        require( block.timestamp > time[msg.sender], "belum mencapai batas lock");
        ERC20(address(this)).transfer(msg.sender , lockBalance[msg.sender] + hadiah);
        Hadiah -= hadiah;
        AllLock -= lockBalance[msg.sender];
        delete lockBalance[msg.sender];
        delete time[msg.sender];
    }

    function getLock() public view returns (uint256) {
        return lockBalance[msg.sender];
    }

    function LockTime() external view returns (uint256 hasil) {
        if( block.timestamp < time[msg.sender] ){
            hasil = time[msg.sender] - block.timestamp;
        }else{
            hasil = 0;
        }
        return hasil;
    }

    function ck() public view returns (uint256) {
        uint256 hasil = Hadiah + AllLock;
        uint256 result = ERC20(address(this)).balanceOf(address(this)) - hasil;
        if(hasil > ERC20(address(this)).balanceOf(address(this))){
            return 0;
        }
        return result;
    }
   
    function tebak(uint256 amount, bool _tebak) public {
        require(tebakactive, "tidak active");
        bool hasilnya = random() % 2 == 1;
        require(amount >= 1 ether, "amount harus setidaknya 1 ether");
        
        if( hasilnya == _tebak){
            _mint(msg.sender, amount);
            emit Tebak(msg.sender, "win" , amount);
        }else{
            _burn(msg.sender, amount);
            emit Tebak(msg.sender, "lose" , amount);
        }
    }

    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, net)));
    }

    function ClaimAirdrop(address referralWallet) public {
       
        require( timeAirdop > block.timestamp , "waktu airdrop sudah terlewat");
        require(!WalletAirdrop[msg.sender], "anda sudah claim airdrop");
        require(msg.sender != referralWallet , "invalid referrals");

        _mint(msg.sender, 100 ether);
        _mint(owner(), 75 ether);
        _mint(referralWallet, 25 ether);

        WalletAirdrop[msg.sender] = true;

        emit Airdrop(msg.sender , 100 ether , block.timestamp);
        emit referralAirdrop(msg.sender , referralWallet , 25 ether, block.timestamp);
    }

    function getsale(uint256 amount) public view returns(uint256 jumlah) {
        if (tahap1 > block.timestamp) {
            jumlah = amount * pricetahap1;
        } else if (tahap2 > block.timestamp) {
            jumlah = amount * pricetahap2;
        } else {
            jumlah = amount * pricetahap3;
        }
            return jumlah;
    }

    function pre_sale() public payable {
       uint256 jumlah;
        if (tahap1 > block.timestamp) {
            jumlah = msg.value * pricetahap1;
        } else if (tahap2 > block.timestamp) {
            jumlah = msg.value * pricetahap2;
        } else {
            jumlah = msg.value * pricetahap3;
        }
            _mint(msg.sender, jumlah);
    }

    function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}