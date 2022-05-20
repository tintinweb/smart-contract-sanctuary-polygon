// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// When called `donate`, it sends pre-defined amount of tokens to the msg.sender
// As a prerequisite, it shall get enough tokens on the balance
contract TestZkpFaucet {
    address public immutable token;
    uint256 public donatAmount;
    uint256 public tokenPrice;
    address public owner;

    // @notice  store the whitelisted addresses who can call the donate function
    mapping(address => bool) public whitelistedAddresses;
    // @notice  store the donate receivers addresses
    mapping(address => bool) public donateReceivers;

    // @notice enabling/disabling check for whitelisted addresses
    bool public restrictToWhitelisted;
    // @notice enabling/disabling check for receiver addresses
    bool public restrictToNonReceivers;

    constructor(
        address _token,
        uint256 _tokenPrice,
        uint256 _donat,
        address _owner
    ) {
        token = _token;
        tokenPrice = _tokenPrice;
        donatAmount = _donat;
        owner = _owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    /**
     * @notice if restrictToWhitelisted is true, then check if the sender is whitelisted
     */
    modifier onlyWhitelisted(address _address) {
        require(
            !restrictToWhitelisted || isWhitelisted(_address),
            "Not whitelisted"
        );
        _;
    }

    /**
     * @notice if restrictToNonReceivers is true, then check if the sender is already received token
     */
    modifier onlyNonReceiver(address _address) {
        require(
            !restrictToNonReceivers || isNonReceiver(_address),
            "User is already received token"
        );
        _;
    }

    modifier validatePrice() {
        require(msg.value >= tokenPrice, "Low value");
        _;
    }

    /**
     * @notice return true if the address is whitelisted, otherwise false
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistedAddresses[_account];
    }

    /**
     * @notice return true if the address has received token, otherwise false
     */
    function isNonReceiver(address _account) public view returns (bool) {
        return donateReceivers[_account];
    }

    /**
     * @notice toggle restrictToWhitelisted
     */
    function toggleRestrictToWhitelisted() external onlyOwner {
        restrictToWhitelisted = !restrictToWhitelisted;
    }

    /**
     * @notice toggle restrictToNonReceivers
     */
    function toggleRestrictToNonReceivers() external onlyOwner {
        restrictToNonReceivers = !restrictToNonReceivers;
    }

    /**
     * @notice Add multiple addresses to the whitelisted list
     * @param _whitelistedAddresses array of addresses to be added
     * @param _whitelisted array of boolen values to be mapped to the addresses
     */
    function addWhitelistedMultiple(
        address[] calldata _whitelistedAddresses,
        bool[] calldata _whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < _whitelistedAddresses.length; ) {
            whitelistedAddresses[_whitelistedAddresses[i]] = _whitelisted[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice update the amount that can be received by users
     * @param _donatAmount the amount that can be received by users
     */
    function updateDonateAmount(uint256 _donatAmount) external onlyOwner {
        donatAmount = _donatAmount;
    }

    /**
     * @notice send tokens to `_to`
     * @param _to the receiver addresss
     * @dev if restrictToWhitelisted is true, then check if the
     * sender is whitelisted.
     * if the restrictToNonReceivers is true, then check if the
     * sender is already received token.
     */
    function donate(address _to)
        external
        payable
        validatePrice
        onlyWhitelisted(msg.sender)
        onlyNonReceiver(_to)
    {
        uint256 amount = tokenPrice > 0
            ? calculateDonateAmount(msg.value)
            : donatAmount;

        safeTransfer(token, _to, amount);
        donateReceivers[_to] = true;
    }

    function calculateDonateAmount(uint256 _amountToPay)
        public
        view
        returns (uint256)
    {
        return _amountToPay / tokenPrice;
    }

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }
}