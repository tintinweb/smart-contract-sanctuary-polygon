// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./UserCampaigns.sol";

interface IEmissionFeeds {
    function latestResponse() external view returns (bytes memory);
}

error CarbonMarketplace__invalidAdmin();
error CarbonMarketplace__duplicateAdmin();
error CarbonMarketplace__notAdmin();
error CarbonMarketplace__alreadyApproved();
error CarbonMarketplace__alreadyDeployed();
error CarbonMarketplace__invalidProjectId();
error CarbonMarketplace__alreadyNotApproved();
error CarbonMarketplace__notEnoughApprovals();
error CarbonMarketplace__invalidAuthor();
error CarbonMarketplace__projectNotApproved();
error CarbonMarketplace__reviewNotRequired();

contract CarbonMarketplace is ERC20 {
    struct Emission {
        int256 CO;
        int256 NO2;
        int256 SO2;
        int256 PM2_5;
        int256 PM10;
    }

    struct Project {
        address author;
        string projectName;
        string projectLink;
        string zipCode;
        bool accepted;
        uint256 approvals;
        address authorCampaignContract;
        Emission latestEmissionFeeds;
        uint256 latestReviewTimestamp;
    }


    address[] public admins;
    mapping(address => bool) private _isAdmin;
    uint256 public approvalsRequired;

    Project[] public projects;
    mapping(uint256 => mapping(address => bool)) public approved;
    uint256 public totalProjects;
    uint256 public acceptedProjects;

    IEmissionFeeds public emissionFeeds;
    IWeatherFeeds public weatherFeeds;
    uint256 public reviewInterval;

    // Events
    event ProposalSubmitted(uint256 indexed projectId, address indexed author, string indexed projectName);
    event Approved(uint256 indexed projectId, address indexed validator);
    event Revoked(uint256 indexed projectId, address indexed validator);
    event ProposalAccepted(uint256 indexed projectId, address indexed admin);
    event TokenRewarded(uint256 indexed projectId, address indexed author, uint256 indexed tokens);


    constructor(address[] memory _admins, uint256 _approvalsRequired, address _emissionFeeds, address _weatherFeeds, uint256 _reviewInterval) ERC20("Carbon Coin", "CC") {
        require(_approvalsRequired > 0 && _approvalsRequired <= _admins.length, "Invalid number of approvers");
        require(_admins.length > 0, "Atleast one admin required");

        for (uint256 i=0; i<_admins.length; i++) {
            if (_admins[i] == address(0)) {
                revert CarbonMarketplace__invalidAdmin();
            }

            if (_isAdmin[_admins[i]]) {
                revert CarbonMarketplace__duplicateAdmin();
            }

            admins.push(_admins[i]);
            _isAdmin[admins[i]] = true;
        }

        approvalsRequired = _approvalsRequired;
        totalProjects = 0;
        acceptedProjects = 0;

        emissionFeeds = IEmissionFeeds(_emissionFeeds);
        weatherFeeds = IWeatherFeeds(_weatherFeeds);
        reviewInterval = _reviewInterval;
    }

    modifier onlyAdmins {
        if (!_isAdmin[msg.sender]) {
            revert CarbonMarketplace__notAdmin();
        }
        _;
    }

    modifier projectExist(uint256 id) {
        if (id >= projects.length) {
            revert CarbonMarketplace__invalidProjectId();
        }
        _;
    }

    modifier notApproved(uint256 id) {
        if (approved[id][msg.sender]) {
            revert CarbonMarketplace__alreadyApproved();
        }
        _;
    }

    modifier isApproved(uint256 id) {
        if (!approved[id][msg.sender]) {
            revert CarbonMarketplace__alreadyNotApproved();
        }
        _;
    }

    modifier notDeployed(uint256 id) {
        if (projects[id].accepted) {
            revert CarbonMarketplace__alreadyDeployed();
        }
        _;
    }


    function submitProposal(string memory projectName, string memory projectLink, string memory pinCode, string memory countryCode) external {
        if (msg.sender != tx.origin) {
            revert CarbonMarketplace__invalidAuthor();
        }

        uint256 id = totalProjects;
        totalProjects++;

        projects.push(Project(
            msg.sender,
            projectName,
            projectLink,
            string.concat(pinCode, ',', countryCode),
            false,
            0,
            address(0),
            Emission(0,0,0,0,0),
            0
        ));

        emit ProposalSubmitted(id, msg.sender, projectName);
    }

    function giveApproval(uint256 projectId) external onlyAdmins projectExist(projectId) notApproved(projectId) notDeployed(projectId) {
        approved[projectId][msg.sender] = true;
        projects[projectId].approvals++;

        emit Approved(projectId, msg.sender);
    }

    function revoke(uint256 projectId) external onlyAdmins projectExist(projectId) notDeployed(projectId) isApproved(projectId) {
        approved[projectId][msg.sender] = false;
        projects[projectId].approvals--;

        emit Revoked(projectId, msg.sender);
    }

    function deployProject(uint256 projectId) external onlyAdmins projectExist(projectId) notDeployed(projectId) {
        if (projects[projectId].approvals < approvalsRequired) {
            revert CarbonMarketplace__notEnoughApprovals();
        }

        Project storage authorProject = projects[projectId];
        authorProject.accepted = true;
        acceptedProjects++;

        bytes memory data = emissionFeeds.latestResponse();
        (int256 co, int256 no2, int256 so2, int256 pm2_5, int256 pm10) = abi.decode(data, (int256, int256, int256, int256, int256));
        projects[projectId].latestEmissionFeeds = Emission(co, no2, so2, pm2_5, pm10);
        projects[projectId].latestReviewTimestamp = block.timestamp;

        authorProject.authorCampaignContract = address(new UserCampaign(
            projectId, 
            authorProject.projectName, 
            authorProject.author,
            address(weatherFeeds)
        ));

        emit ProposalAccepted(projectId, msg.sender);
    }

    function reviewProject(uint256 projectId) external onlyAdmins projectExist(projectId) {
        if (!projects[projectId].accepted) {
            revert CarbonMarketplace__projectNotApproved();
        }

        Project storage userProject = projects[projectId];

        if ((block.timestamp - userProject.latestReviewTimestamp) < reviewInterval) {
            revert CarbonMarketplace__reviewNotRequired();
        }

        userProject.latestReviewTimestamp = block.timestamp;

        bytes memory data = emissionFeeds.latestResponse();
        (int256 co, int256 no2, int256 so2, int256 pm2_5, int256 pm10) = abi.decode(data, (int256, int256, int256, int256, int256));

        uint256 totalTokens = 0;
        if (co < userProject.latestEmissionFeeds.CO) {
            totalTokens += 10;
        }
        if (no2 < userProject.latestEmissionFeeds.NO2) {
            totalTokens += 10;
        }
        if (so2 < userProject.latestEmissionFeeds.SO2) {
            totalTokens += 10;
        }
        if (pm2_5 < userProject.latestEmissionFeeds.PM2_5) {
            totalTokens += 10;
        }
        if (pm10 < userProject.latestEmissionFeeds.PM10) {
            totalTokens += 10;
        }
        
        _mint(userProject.author, totalTokens * 1e18);

        emit TokenRewarded(projectId, userProject.author, totalTokens);

        userProject.latestEmissionFeeds = Emission(co, no2, so2, pm2_5, pm10);
    }

    function getApprovedProjects() external view returns (Project[] memory) {
        Project[] memory allProjects = new Project[](acceptedProjects);
        
        uint256 counter = 0;
        for (uint256 i=0; i<projects.length; i++) {
            if (projects[i].accepted) {
                allProjects[counter] = projects[i];
                counter++;
            }
        }

        return allProjects;
    }

    function getNotApprovedProjects() external view onlyAdmins returns (Project[] memory) {
        Project[] memory allProjects = new Project[](projects.length - acceptedProjects);
        
        uint256 counter = 0;
        for (uint256 i=0; i<projects.length; i++) {
            if (!projects[i].accepted) {
                allProjects[counter] = projects[i];
                counter++;
            }
        }

        return allProjects;
    }

    

    function getProjectAt(uint256 projectId) external projectExist(projectId) view returns (Project memory) {
        return projects[projectId];
    }
    
    function isAdmin(address addr) external view returns (bool) {
        return _isAdmin[addr];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {CarbonMarketplace} from "./CarbonMarketplace.sol";

error CarbonMerch__notAdmin();
error CarbonMerch__zeroQty();
error CarbonMerch__invalidProductId();
error CarbonMerch__invalidOrderId();
error CarbonMerch__buyAtLeastOneProduct();
error CarbonMerch__qtyError();
error CarbonMerch__alreadyPacked();
error CarbonMerch__alreadyShipped();
error CarbonMerch__alreadyOutForDelivery();
error CarbonMerch__alreadyDelivered();

contract CarbonMerch {
    enum Category {
        electronics,
        stationary,
        household,
        fashion,
        organic
    }

    enum OrderStatus {
        Booked,
        Packed,
        Shipped,
        OutForDelivery,
        Delivered
    }

    struct Product {
        string name;
        string description;
        uint256 qty;
        uint256 cost;
        string imageURI;
        Category category;
    }

    struct Order {
        uint256 orderId;
        address consumer;
        uint256 purchaseTime;
        string residentialAddress;
        OrderStatus status;
        uint256[] productIds;
        uint256[] qty;
    }

    CarbonMarketplace private carbonMarketplace;
    Product[] private products;
    Order[] private orders;
    mapping(address => uint256[]) private consumerToOrderIds;

    // Events
    event productAdded(string indexed name, uint256 indexed id);
    event orderPlaced(uint256 indexed orderId, address indexed consumer, uint256 indexed bill);
    event orderPacked(uint256 indexed orderId);
    event orderShipped(uint256 indexed orderId);
    event orderOutForDelivery(uint256 indexed orderId);
    event orderDelivered(uint256 indexed orderId);

    constructor(address carbonMarketplaceAddr) {
        carbonMarketplace = CarbonMarketplace(carbonMarketplaceAddr);
    }

    modifier onlyAdmins() {
        if (!carbonMarketplace.isAdmin(msg.sender)) {
            revert CarbonMerch__notAdmin();
        }
        _;
    }

    modifier orderIdExist(uint256 orderId) {
        if (orderId >= orders.length) {
            revert CarbonMerch__invalidOrderId();
        }
        _;
    }

    function addProduct(
        string memory name, 
        string memory desc, 
        uint256 initQty, 
        uint256 cost,
        string memory imageURI, 
        Category category
    ) public onlyAdmins {
        if (initQty == 0) {
            revert CarbonMerch__zeroQty();
        }

        products.push(Product({
            name: name,
            description: desc,
            qty: initQty,
            cost: cost,
            imageURI: imageURI,
            category: category
        }));

        emit productAdded(name, products.length);
    }

    function addQty(uint256 productId, uint256 extraQty) public onlyAdmins {
        if (productId >= products.length) {
            revert CarbonMerch__invalidProductId();
        }

        if (extraQty == 0) {
            revert CarbonMerch__zeroQty();
        }

        products[productId].qty += extraQty;
    }

    /**@param productIds It contains the ids of products the consumer wants to buy
     * @param qty It contains the corresponding quantity of product in productIds array
     * @param residentialAddress The address of consumer to deliver the swags 
    */
    function buyProduct(uint256[] memory productIds, uint256[] memory qty, string memory residentialAddress) public {
        require(productIds.length == qty.length);

        if (productIds.length == 0) {
            revert CarbonMerch__buyAtLeastOneProduct();
        }

        uint256 bill = 0;

        uint256 totalProducts = products.length;

        for (uint256 i = 0; i < productIds.length; i++) {
            if (productIds[i] >= totalProducts) {
                revert CarbonMerch__invalidProductId();
            }

            Product memory product = products[productIds[i]];

            if (qty[i] == 0 || qty[i] > product.qty) {
                revert CarbonMerch__qtyError();
            }

            products[productIds[i]].qty -= qty[i];
            bill += product.cost;
        }

        // Pay Amount
        carbonMarketplace.transferFrom(msg.sender, address(this), bill);

        uint256 orderId = orders.length;

        orders.push(Order({
            orderId: orderId,
            consumer: msg.sender,
            purchaseTime: block.timestamp,
            residentialAddress: residentialAddress,
            status: OrderStatus.Booked,
            productIds: productIds,
            qty: qty
        }));

        consumerToOrderIds[msg.sender].push(orderId);

        emit orderPlaced(orderId, msg.sender, bill);
    }

    function markAsPacked(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.Booked)) {
            revert CarbonMerch__alreadyPacked();
        }

        orders[orderId].status = OrderStatus.Packed;
        
        emit orderPacked(orderId);
    } 

    function markAsShipped(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.Shipped)) {
            revert CarbonMerch__alreadyShipped();
        }

        orders[orderId].status = OrderStatus.Shipped;

        emit orderShipped(orderId);
    }

    function markAsOutForDelivery(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.OutForDelivery)) {
            revert CarbonMerch__alreadyOutForDelivery();
        }

        orders[orderId].status = OrderStatus.OutForDelivery;

        emit orderOutForDelivery(orderId);
    }

    function markAsDelivered(uint256 orderId) public onlyAdmins orderIdExist(orderId) {
        if (uint256(orders[orderId].status) >= uint256(OrderStatus.Delivered)) {
            revert CarbonMerch__alreadyDelivered();
        }

        orders[orderId].status = OrderStatus.Delivered;

        emit orderDelivered(orderId);
    }

    function trackOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    } 

    function getAllConsumerOrders(address consumer) external view returns (Order[] memory) {
        uint256 length = consumerToOrderIds[consumer].length;

        Order[] memory myOrder = new Order[](length);

        for (uint i = 0; i < length; i++) {
            myOrder[i] = orders[consumerToOrderIds[consumer][i]];
        }

        return myOrder;
    }

    function getAllProducts() external view returns (Product[] memory) {
        return products;
    }

    function getProductAtIdx(uint256 productId) external view returns (Product memory) {
        return products[productId];
    }

    function getCarbonMarketplace() external view returns (address) {
        return address(carbonMarketplace);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IWeatherFeeds {
    function latestResponse() external view returns (bytes memory);
}

error UserCampaign__notOwner();
error UserCampaign__invalidOwner();
error UserCampaign__notEnoughETH();
error UserCampaign__ownerCantSendETH();
error UserCampaign__txnFailed();

contract UserCampaign {
    struct Logs {
        uint256 timestamp;
        string caption;
        string location;
        string currentWeather;
    }

    uint256 public projectID;
    string public projectName;
    address public immutable owner;
    address[] public donators;
    mapping(address => uint256) public donationsBy;
    Logs[] public logs;
    IWeatherFeeds public weatherFeeds;
    
    // Events
    event donationsReceived(address indexed donator, uint256 indexed amount);
    event logsAdded(string indexed caption, string indexed location, uint256 indexed timestamp);
    event withdrawn(address indexed owner, uint256 indexed amount);

    constructor(uint256 _id, string memory _projectName, address author, address _weatherFeeds) {
        projectID = _id;
        projectName = _projectName;
        owner = author;
        weatherFeeds = IWeatherFeeds(_weatherFeeds);
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert UserCampaign__notOwner();
        }
        _;
    }

    function addLogs(string memory caption, string memory location) external onlyOwner {
        // take the weather from contract
        string memory weather = string(weatherFeeds.latestResponse());

        logs.push(Logs(
            block.timestamp,
            caption,
            location,
            weather
        ));

        emit logsAdded(caption, location, block.timestamp);
    }

    function donateToCampaign() external payable {
        if (msg.value == 0) {
            revert UserCampaign__notEnoughETH();
        }

        if (msg.sender == owner) {
            revert UserCampaign__ownerCantSendETH();
        }

        if (donationsBy[msg.sender] == 0) {
            donators.push(msg.sender);
        }

        donationsBy[msg.sender] += msg.value;

        emit donationsReceived(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        if (amount == 0) {
            revert UserCampaign__notEnoughETH();
        }

        (bool success, ) = payable(owner).call{value: amount}("");

        if (!success) {
            revert UserCampaign__txnFailed();
        }

        emit withdrawn(owner, amount);
    }

    function getAllDonations() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory amountDonated = new uint256[](donators.length);

        for (uint256 i=0; i<donators.length; i++) {
            amountDonated[i] = donationsBy[donators[i]];
        }

        return (donators, amountDonated);
    }

    function getAllLogs() public view returns (Logs[] memory) {
        return logs;
    }
}