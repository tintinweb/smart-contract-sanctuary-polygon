// SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
pragma solidity ^0.8.9;

contract Token is IERC20, Ownable {

    string private _name;
    string private _symbol;

    uint8 private _decimals;
    uint256 public _totalSupply;
    uint256 public whaleAmount;
    uint256 public totalVestings;
    // TODO check
    uint256 public immutable totalSupplyLimit = 2 ** 256 - 1;

    bool public antiWhale;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(uint256 => VestingDetails) public vestingID;
    mapping(address => uint256[]) receiverIDs;
    mapping(address => bool) public isWhitelistedFromWhaleAmount;
    mapping(address => bool) public isBlacklisted;

    event whaleAmountUpdated(
        uint256 oldAmount,
        uint256 newAmount,
        uint256 time
    );
    event antiWhaleUpdated(bool status, uint256 time);
    event UpdatedWhitelistedAddress(address _address, bool isWhitelisted);
    event UpdatedBlacklistedAddress(address _address, bool isBlacklisted);
    event TokensMinted(address to, uint256 amount);

    struct VestingDetails {
        address receiver;
        uint256 amount;
        uint256 release;
        bool expired;
    }

    /**
     * @dev Constructor.
     * @param __name name of the token
     * @param __symbol symbol of the token, 3-4 chars is recommended
     * @param __decimals number of decimal places of one token unit, 18 is widely used
     * @param __totalSupply total supply of tokens in lowest units (depending on decimals)
     * @param _antiWhale to enable the antiwhale feature on/off, by default value is false.
     * @param _whaleAmount whale amount of tokens in lowest units (depending on decimals)
     * @param owner address that gets 100% of token supply
     */
    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 __totalSupply,
        bool _antiWhale,
        uint256 _whaleAmount,
        address owner
    ) Ownable(owner) {
        require(owner != address(0), "Owner can't be zero address");
        require(_whaleAmount < __totalSupply, "Whale amount must be lower than total supply");

        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _owner = owner;
        whaleAmount = _whaleAmount * 10**__decimals;
        antiWhale = _antiWhale;
        _totalSupply = __totalSupply * 10**__decimals;

        // set tokenOwnerAddress as owner of all tokens and the owner has the control of antiWhale feature if enabled.
        _balances[_owner] = _totalSupply;

        // Event
        emit Transfer(address(0), _owner, _totalSupply);

    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return the total supply of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Allows the owner to change the whale amount per transaction
     * @param _amount The amount of lowest token units to be set as whaleAmount
     * @return _success true (bool) if the flow was successful
     */
    function updateWhaleAmount(uint256 _amount)
        external
        onlyOwner
        returns (bool _success)
    {
        require(antiWhale, "Anti whale is turned off");
        uint256 oldAmount = whaleAmount;
        whaleAmount = _amount;
        emit whaleAmountUpdated(oldAmount, whaleAmount, block.timestamp);
        return true;    
    }

    /**
     * @dev Allows the owner to turn the anti whale feature on/off.
     * @param status disable (false) / enable (enable) bool value
     * @return _success true (bool) if the flow was successful
     */
    function updateAntiWhale(bool status) external onlyOwner returns (bool _success) {
        antiWhale = status;
        emit antiWhaleUpdated(antiWhale, block.timestamp);
        return true;
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @param spender Address of spender
     * @param value uint amount that spender is approved by msg.sender to spend
     * @return _success bool (true) if flow was successful
     *
     * Approves spender to spend value tokens from msg.sender
     */
    function approve(address spender, uint256 value) public returns (bool _success) {
        _approve(msg.sender, spender, value);
        return true;
    }

        /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * @param owner Address of owner of token who sets allowance for spender to use the owner's tokens
     * @param spender Address of spender whose allowance is being set by msg.sender
     * @param value Value by which spender's allowance is being reduced
     * @return _success bool value => true if flow was successful
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal returns (bool _success) {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }

        /**
     * @dev See `IERC20.allowance`.
     * @param owner Address of the owner of the tokens
     * @param spender Address of the spender of the owners's tokens
     * @return the amount of token set by owner for spender to spend
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

        /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * @param spender Address of spender whose allowance is being increased by msg.sender
     * @param addedValue Value by which spender's allowance is being increased
     * @return _success bool value => true if flow was successful
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool _success)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @param spender Address of spender whose allowance is being increased by msg.sender
     * @param subtractedValue Value by which spender's allowance is being reduced
     * @return _success bool value => true if flow was successful 
     *   
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool _success)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @param _address Address of the user
     * @param _isWhitelisted boolean (true or false), whether the address must be enabled/disabled from whitelist
     * @return success Boolean value => true if flow was successful
     * Updates an account's status in the whitelistFromWhaleAmount (enable/disable)
     */
    function updateWhitelistedAddressFromWhale(address _address, bool _isWhitelisted) public onlyOwner
    returns(bool success){
        isWhitelistedFromWhaleAmount[_address] = _isWhitelisted;
        emit UpdatedWhitelistedAddress(_address, _isWhitelisted);
        return true;
    }

    function updateBlacklistedAddress(address _address, bool _isBlacklisted) external onlyOwner returns(bool success){
        isBlacklisted[_address] = _isBlacklisted;
        emit UpdatedBlacklistedAddress(_address, _isBlacklisted);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * @param sender Address of sender whose is transferring amount to the recipient
     * @param recipient Address of the receiver of tokens from the sender
     * @param amount Amount of tokens being transferred by sender to the recipient
     * @return _success Boolean value => true if flow was successful
     *
     *Transfers {amount} token from sender to recipient
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool _success) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    /**
     * @dev See `IERC20.transfer`.
     * @param recipient Address of the receiver of tokens from the sender
     * @param amount Amount of tokens being transferred by sender to the recipient
     * @return _success Boolean value true if the flow is successful
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool _success) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

        /**
     * @dev Allows the caller to airdrop tokens.
     * @param users Addresses of the users.
     * @param amounts Token values to the corresponding users.
     * @param totalSum Total sum of the tokens to be airdropped to all users.
     * @return _success true (bool) if the flow was successful
     */
    function multiSend(
        address[] memory users,
        uint256[] memory amounts,
        uint256 totalSum
    ) external returns (bool _success) {
        require(users.length == amounts.length, "Length mismatch");
        require(totalSum <= balanceOf(msg.sender), "Not enough balance");

        for (uint256 i = 0; i < users.length; i++) {
            _transfer(msg.sender, users[i], amounts[i]);
        }
        return true;
    }

    /**
     * @param from Address of sender whose is transferring amount to the recipient
     * @param to Address of the receiver of tokens from the sender
     * @param amount Amount of tokens being transferred by sender to the recipient
     * @return _success Boolean value => true if flow was successful
     * Transfers amount from {from} to {to}
     * Checks for antiWhale
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool _success) {
        
        require(!isBlacklisted[from] , "Sender is backlisted");
        require(!isBlacklisted[to], "Recipient is backlisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Checking for anti-whale
        if (antiWhale) {

            require(amount <= whaleAmount, "Transfer amount exceeds max amount");

            //If account is not whitelisted from whale amount, then checking if total balance will be greater than whale amount 
            if(!isWhitelistedFromWhaleAmount[to]){
                require(
                    balanceOf(to) + amount <= whaleAmount,
                    "Recipient amount exceeds max amount"
                );
            }
        }
        unchecked {
            require(balanceOf(from) >= amount, "Amount exceeds balance");
            _balances[from] = _balances[from] - amount;
        }

        // SafeMath for addition overflow built-in
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @param account Address of account
     * @return Number of tokens owned by the account
     * Returns the balance of tokens of the account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
    * @param _receiver Address of the receiver of the vesting
    * @param _amount Amount of tokens to be locked up for vesting
    * @param _release Timestamp of the release time
    * @return _success Boolean value true if flow is successful
    * Creates a new vesting
    */
    function createVesting(
        address _receiver,
        uint256 _amount,
        uint256 _release
    ) public returns (bool _success) {
        require(_receiver != address(0), "Zero receiver address");
        require(_amount > 0, "Zero amount");
        require(_release > block.timestamp, "Incorrect release time");

        totalVestings++;
        vestingID[totalVestings] = VestingDetails(
            _receiver,
            _amount,
            _release,
            false
        );
        // Adds the vesting id corresponding to the receiver
        receiverIDs[_receiver].push(totalVestings);
        require(_transfer(msg.sender, address(this), _amount));
        return true;
    }

        /**
    * @param _receivers Arrays of address of receiver of vesting amount
    * @param _amounts Array of amounts corresponding to each vesting
    * @param _releases Array of release timestamps corresponding to each vesting
    * @return _success Boolean value true if flow is successful
    * Creates multiple vesting, calls createVesting for each corresponding entry in {_receivers} {_amounts} {_releases}
    */
    function createMultipleVesting(
        address[] memory _receivers,
        uint256[] memory _amounts,
        uint256[] memory _releases
    ) external returns (bool _success) {
        require(
            _receivers.length == _amounts.length &&
                _amounts.length == _releases.length,
            "Invalid data"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            bool success = createVesting(
                _receivers[i],
                _amounts[i],
                _releases[i]
            );
            require(success, "Creation of vesting failed");
        }
        return true;
    }

        /**
    * @param id Id of the vesting
    * @return Boolean value true if flow is successful
    * Returns the release timestamp of the the vesting
    */
    function getReleaseTime(uint256 id) public view returns(uint256){
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(!vestingDetail.expired, "ID expired");
        return vestingDetail.release;
    }

    /**
    * @param id Id of the vesting
    * @return _success Boolean value true if flow is successful
    * The receiver of the vesting can claim their vesting if the vesting ID corresponds to their address 
    * and hasn't expired
    */
    function claim(uint256 id) external returns (bool _success) {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(msg.sender == vestingDetail.receiver, "Caller is not the receiver");
        require(!vestingDetail.expired, "ID expired");
        require(
            block.timestamp >= vestingDetail.release,
            "Release time not reached"
        );
        vestingID[id].expired = true;
        require(_transfer(
            address(this),
            vestingDetail.receiver,
            vestingDetail.amount
        ));
        return true;
    }

    /**
    * @param user Address of receiver of vesting amount
    * @return Array of IDs corresponding to vesting assigned to the user
    * Returns the IDs of the vestings , the user corresponds to
    */
    function getReceiverIDs(address user)
        external
        view
        returns (uint256[] memory)
    {
        return receiverIDs[user];
    }

    // Owner can mint tokens to any address
    function mintTokens(address to, uint256 amount) external onlyOwner{
        require(_totalSupply + amount <= totalSupplyLimit);
        _balances[to] += amount;
        _totalSupply += amount;
        emit TokensMinted(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Context {
    /**
     * @return Address of the transaction message sender {msg.sender}
     * Returns the msg.sender
     */
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @param tokenOwner address of the token owner
     * Transfers ownership to tokenOwner
     */
    constructor(address tokenOwner) {
        _transferOwnership(tokenOwner);
    }

    /**
     * @return Address of the owner of the contract
     * Returns the owner address
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Modifier that checks if the msg.sender is the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return Boolean value true if flow was successful
     * Only owner can call the function
     * Releases ownership to address 0x0
     */
    function renounceOwnership() public onlyOwner returns(bool) {
        _transferOwnership(address(0));
        return true;
    }
    
    /**
     * @return Boolean value true if flow was successful
     * Only owner can call the function
     * Releases ownership to address newOwner
     */
    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
        return true;
    }

    /**
     * Sets newOwner as the owner and emits the OwnershipTransferred event
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}