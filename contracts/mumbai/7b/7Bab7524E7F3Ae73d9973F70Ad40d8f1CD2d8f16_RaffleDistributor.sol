// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

interface IRaffleTicket {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function mint(address to, uint256 amount) external returns (bool);
}

contract RaffleDistributor {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Emitted after a Raffles has been purchased by `user`.
     */
    event RafflesPurchased(address user, uint256 amount);

    mapping(address => bool) private _owner;
    bool private _paused;

    address public RAFFLE_TICKET_ADDRESS;
    address public VAULT;

    uint256 public RAFFLE_TICKET_PRICE;
    uint256 public MAX_RAFFLE_PER_USER;

    constructor(
        address[] memory owner,
        address raffleaddr,
        address vaultaddr,
        uint256 price_per_raffleticket_in_wei,
        uint256 max_raffle_per_user
    ) {
        for (uint256 i = 0; i < owner.length; i++) {
            _owner[owner[i]] = true;
        }
        _paused = true;
        RAFFLE_TICKET_ADDRESS = raffleaddr;
        VAULT = vaultaddr;
        RAFFLE_TICKET_PRICE = price_per_raffleticket_in_wei;
        MAX_RAFFLE_PER_USER = max_raffle_per_user;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            isOwner(_msgSender()),
            "RaffleDistributor: caller is not the owner"
        );
        _;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) public view virtual returns (bool) {
        return _owner[caller];
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "RaffleDistributor#Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "RaffleDistributor#Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Returns true if `account` is the contract address.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev User can buy `quantity` RaffleTicket with valid price(RAFFLE_TICKET_PRICE * quantity)
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The `quantity` must not exceed `MAX_RAFFLE_PER_USER`.
     */
    function buyRaffle(uint256 quantity)
        external
        payable
        whenNotPaused
        returns (bool)
    {
        require(
            !isContract(_msgSender()),
            "RaffleDistributor#buy: no contract allowed"
        );
        require(
            msg.value == RAFFLE_TICKET_PRICE * quantity,
            "RaffleDistributor#buy: Price does not match"
        );
        uint256 balance = IRaffleTicket(RAFFLE_TICKET_ADDRESS).balanceOf(
            _msgSender()
        );
        require(
            balance + quantity <= MAX_RAFFLE_PER_USER,
            "RaffleDistributor#buy: Max Raffle Buy Limit Exceeded"
        );

        // transfers ether to Vault
        (bool sent, ) = VAULT.call{value: msg.value}("");
        require(sent, "RaffleDistributor#buy: Payment Failed ");

        // mint Raffle Ticket to the caller
        require(
            IRaffleTicket(RAFFLE_TICKET_ADDRESS).mint(_msgSender(), quantity)
        );
        emit RafflesPurchased(_msgSender(), quantity);
        return true;
    }
}