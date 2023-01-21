/**
 *Submitted for verification at polygonscan.com on 2023-01-21
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

    function totalBurn() external view returns (uint256);

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
    uint256 private _totalBurn;
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
    function totalBurn() public view virtual override returns (uint256) {
        return _totalBurn;
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
        uint256 fee = amount * 5 / 10000; // fee 0,05%
        unchecked {
            _balances[from] = fromBalance - amount - fee;
        }
        _balances[to] += amount - fee;
        _burn(from,fee);

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

    function _burnLock(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burnLock from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burnLock amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        _afterTokenTransfer(account, address(0), amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        if(_totalBurn + amount < 2**256 - 1){
            _totalBurn += amount;
        }else{
            _totalBurn = 0;
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
    /** * presale * **/
    uint256 private tahap1;
    uint256 private tahap2;
    uint256 private tahap3;
    uint16 private pricetahap1;
    uint16 private pricetahap2;
    uint16 private pricetahap3;
    event Presale(address indexed pembeli, uint256 amount);
    /** * waktu * **/
    uint256 private waktu;
    /** * Lock * **/
    struct LockWallet {
        address wallet;
        uint256 waktuLock;
        uint256 batasWaktuUnlock;
        uint256 amountLocked;
        uint32 bunga;
    }
    event Lock(address indexed owner, uint256 amount);
    event UnLock(address indexed owner, uint256 amount);
    mapping (address => LockWallet) public lockWallets;

    bool public pauseLock;
    uint256 public TokenLock;
    uint256 public RewardLock;

    /** * marketing * **/
    address public marketing;
    /** * Airdrop * **/
    event Airdrop(address indexed wallet , uint256 amount , uint256 waktu);
    event referralAirdrop(address indexed dari , address indexed penerima , uint256 amount, uint256 waktu);
    mapping (address => bool) public AirdropWallet;
    uint256 timeAirdop;

    constructor(address _marketing) ERC20("LITER", "LTR") {
        waktu = 30 days;
        marketing = _marketing;
        timeAirdop = block.timestamp + 60 days;
        pauseLock = true;
        _mint(marketing,9900000000 ether);
        _mint(msg.sender,100000000 ether);
    }
    
    function burn(uint256 amount) public {
       _burn(msg.sender, amount);
    }

    /** * presale * **/
    function presale() public payable {
       uint256 jumlah;
        if (tahap1 > block.timestamp) {
            jumlah = msg.value * pricetahap1;
        } else if (tahap2 > block.timestamp) {
            jumlah = msg.value * pricetahap2;
        } else if ( tahap3 > block.timestamp) {
            jumlah = msg.value * pricetahap3;
        }else{
        require(tahap1 > block.timestamp || tahap2 > block.timestamp || tahap3 > block.timestamp, "presale berakhir");
        }
            _mint(msg.sender, jumlah);
            emit Presale(msg.sender, jumlah);
    }
    function getpresale(uint256 amount) public view returns(uint256 hasil) {
        if (tahap1 > block.timestamp) {
            hasil = amount * pricetahap1;
        } else if (tahap2 > block.timestamp) {
            hasil = amount * pricetahap2;
        } else if(tahap3 > block.timestamp){
            hasil = amount * pricetahap3;
        } else{
            hasil = 0;
        }
            return hasil;
    }
    function setpresale(uint16 _tahap1,uint16 _tahap2, uint16 _tahap3) public onlyOwner {
        pricetahap1 = _tahap1;
        pricetahap2 = _tahap2;
        pricetahap3 = _tahap3;

        tahap1 = block.timestamp + waktu;
        tahap2 = tahap1 + waktu;
        tahap3 = tahap2 + waktu;
    }
    
    function timePresale() public view returns(uint256 jumlah) {
        if (tahap1 > block.timestamp) {
            jumlah = tahap1 - block.timestamp;
        } else if (tahap2 > block.timestamp) {
            jumlah = tahap2 - block.timestamp;
        } else if (tahap3 > block.timestamp) {
            jumlah = tahap3 - block.timestamp;
        }else{
            jumlah = 0;
        }
        return jumlah;
    }

    /** * waktu * **/
    function waktux(uint8 kali) private view returns(uint256){
        uint256 result = waktu * kali;
        return result;
    }
    /** * Lock * **/
    function setpauselock(bool _pause) public onlyOwner {
        pauseLock = _pause;
    }
    function lock(uint8 _bulan, uint256 _amountLocked) public {

        uint8 APR;
        require(pauseLock, "pause lock");
        require(_amountLocked > 0, "Tidak ada jumlah yang mau dikunci");
        require(lockWallets[msg.sender].amountLocked == 0, "Wallet sudah dikunci sebelumnya");
        uint256 noww = block.timestamp;
        uint256 _batasWaktuUnlock = noww + waktux(_bulan);
        if( _bulan > 10 ){
            APR = 100;
        }else{
            APR = 10 * _bulan;
        }
        lockWallets[msg.sender] = LockWallet(msg.sender, noww, _batasWaktuUnlock, _amountLocked, APR);
        TokenLock += _amountLocked;
        _burnLock(msg.sender,_amountLocked);
        emit Lock(msg.sender, _amountLocked);
    }
    function unlock() public {
        require(lockWallets[msg.sender].wallet == msg.sender, "Anda tidak memiliki hak untuk meng-unlock wallet ini");
        require(block.timestamp >= lockWallets[msg.sender].batasWaktuUnlock, "Waktu unlock belum tiba");
        require(lockWallets[msg.sender].amountLocked > 0, "Tidak ada jumlah yang terkunci");

        // Proses unlock
        address wallet = lockWallets[msg.sender].wallet;
        uint256 amountLocked = lockWallets[msg.sender].amountLocked;
        uint256 waktuLock = lockWallets[msg.sender].waktuLock;
        uint32 bunga = lockWallets[msg.sender].bunga;
        uint256 reward = Reward(amountLocked , block.timestamp - waktuLock , bunga);

        // Kirim jumlah yang terkunci dan bunga kepada pemilik wallet
        uint256 token = amountLocked + reward;
        TokenLock -= amountLocked;
        if(RewardLock + reward < 2**256 - 1){
            RewardLock += reward;
        }else{
            RewardLock = 0;
        }
        _mint(wallet, token);
        emit UnLock(wallet, token);

        // Reset lockWallet
        lockWallets[msg.sender] = LockWallet(address(0), 0, 0, 0, 0);

    }
    function TimeUnlock(address _addr) public view returns (uint256 hasil) {
        if( lockWallets[_addr].batasWaktuUnlock > block.timestamp ){
            hasil = lockWallets[_addr].batasWaktuUnlock - block.timestamp ;
        }else{
            hasil = 0;
        }
        return hasil;
    }
    function Reward(uint256 amount , uint256 durasi , uint32 bunga) public pure returns(uint256){
        uint256 result = (amount * bunga * durasi) / (100 * 31536000);
        return result;
    }

    /** * Airdrop * **/
    function TimeAirdrop() public view returns (uint256 hasil) {
        if( timeAirdop > block.timestamp ){
            hasil = timeAirdop - block.timestamp;
        }else{
            hasil = 0;
        }
        return hasil;
    }
    function ClaimAirdrop(address referralWallet) public {
        require( TimeAirdrop() != 0 , "waktu airdrop sudah terlewat");
        require(!AirdropWallet[msg.sender], "anda sudah claim airdrop");
        require(msg.sender != referralWallet , "invalid referrals");

        _mint(msg.sender, 100 ether);
        _mint(marketing, 100 ether);
        _mint(referralWallet, 100 ether);

        AirdropWallet[msg.sender] = true;

        emit Airdrop(msg.sender , 100 ether , block.timestamp);
        emit referralAirdrop(msg.sender , referralWallet , 100 ether, block.timestamp);
    }
    function setTimeAirdop(uint8 _bulan) public {
        timeAirdop = block.timestamp + waktux(_bulan);
    }

    function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
    }
}