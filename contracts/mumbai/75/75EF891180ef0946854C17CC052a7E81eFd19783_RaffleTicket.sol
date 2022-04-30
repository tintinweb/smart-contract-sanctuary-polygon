/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.12;

contract RaffleTicket {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event MintAccessGranted(address minter);
    event MintAccessRevoked(address minter);
    event BurnAccessGranted(address burner);
    event BurnAccessRevoked(address burner);
    event TransferPaused(address account);
    event TransferUnPaused(address account);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public name;
    string public symbol;
    uint256 public decimals = 0;

    mapping(address => bool) private _owner;

    mapping(address => bool) public MintAccess;
    mapping(address => bool) public BurnAccess;

    bool private _transferPaused;

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory owner
    ) {
        name = name_;
        symbol = symbol_;
        for (uint256 i = 0; i < owner.length; i++) {
            _owner[owner[i]] = true;
        }
        _transferPaused = true;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), " caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) public view virtual returns (bool) {
        return _owner[caller];
    }

    modifier whenTransferAllowed() {
        require(
            !transferPaused(),
            "RaffleTicket#whenTransferAllowed: Transfer is not allowed"
        );
        _;
    }

    function transferPaused() public view returns (bool) {
        return _transferPaused;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal whenTransferAllowed {
        require(
            from != address(0),
            "RaffleTicket: transfer from the zero address"
        );
        require(to != address(0), "RaffleTicket: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "RaffleTicket: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(
            account != address(0),
            "RaffleTicket: mint to the zero address"
        );

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(
            account != address(0),
            "RaffleTicket: burn from the zero address"
        );

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "RaffleTicket: burn amount exceeds balance"
        );
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    modifier requiresMintAccess() {
        require(
            isOwner(_msgSender()) || MintAccess[_msgSender()],
            "RaffleTicket#requiresMintAccess: No Mint Access"
        );
        _;
    }

    modifier requiresBurnAccess() {
        require(
            isOwner(_msgSender()) || BurnAccess[_msgSender()],
            "RaffleTicket#requiresBurnAccess: No Burn Access"
        );
        _;
    }

    function setMintAccess(address minter, bool val) public onlyOwner {
        MintAccess[minter] = val;
        if (val) {
            emit MintAccessGranted(minter);
        } else {
            emit MintAccessRevoked(minter);
        }
    }

    function setBurnAccess(address burner, bool val) public onlyOwner {
        BurnAccess[burner] = val;
        if (val) {
            emit BurnAccessGranted(burner);
        } else {
            emit BurnAccessRevoked(burner);
        }
    }

    function pauseTransfer() public onlyOwner {
        _transferPaused = true;
        emit TransferPaused(_msgSender());
    }

    function unpauseTransfer() public onlyOwner {
        _transferPaused = false;
        emit TransferUnPaused(_msgSender());
    }

    function mint(address to, uint256 amount)
        public
        requiresMintAccess
        returns (bool)
    {
        require(amount > 0,"RaffleTicket#mint: amount has to be greater than zero");
        _mint(to, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount)
        public
        requiresBurnAccess
        returns (bool)
    {
        _burn(account, amount);
        return true;
    }
}