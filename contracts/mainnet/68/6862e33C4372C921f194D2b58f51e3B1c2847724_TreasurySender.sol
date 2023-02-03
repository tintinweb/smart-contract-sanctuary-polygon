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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract TreasurySender {
    address public owner;
    address public usdcTokenAddress;

    // if true = paused | if false = play
    bool public isPaused;

    uint256 public bpsTxFeeAmount = 300;

    uint256 public txFeeMaticSendToUser = 0.01 ether;

    uint256 public txFeeUsdc = 10000000000000000 wei;

    address payable public revenueWallet;

    IERC20 internal usdcToken;

    event Received(address, uint256);

    event Deposit(address indexed sender, uint256 value);

    event AdminChanged(address newAdmin);

    event TxFeeUsdcChanged(uint256 newFee);

    event TxMentoraChanged(uint256 newFee);

    event TokenTransferCompleted(
        address from,
        address indexed to,
        uint256 amount,
        uint256 feeBpsPercentage,
        uint256 feeAmount,
        uint256 feeUSdc,
        uint256 indexed batchId
    );

    event TransferMatic(address indexed to, uint256 amount);
    event PausedContract(bool isPaused);
    event UnPauseContract(bool isPaused);

    event FeeTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 indexed batchId
    );
    event UsdcTokenAddressChanged(address newUsdcToken);

    struct TransferInfo {
        address payable recipient;
        uint256 amount;
    }

    struct TransferBatch {
        uint256 batchId;
        bool exists;
    }

    mapping(uint256 => TransferBatch) public transferBatches;

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier notPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    modifier addressNotZero(address _address) {
        require(_address != address(0), "Address is zero");
        _;
    }

    modifier atLeastOneTransfer(TransferInfo[] memory _transfers) {
        require(_transfers.length > 0, "No transfers");
        _;
    }

    modifier batchNotExistent(uint256 _batchId) {
        require(!transferBatches[_batchId].exists, "Batch already exists");
        _;
    }

    constructor(address payable _revenueWallet, address _usdcTokenAddress)
        addressNotZero(_revenueWallet)
        addressNotZero(_usdcTokenAddress)
    {
        revenueWallet = _revenueWallet;
        isPaused = false;
        owner = msg.sender;
        usdcTokenAddress = _usdcTokenAddress;
        usdcToken = IERC20(_usdcTokenAddress);
    }

    function getUSDCDecimals() public view returns (uint8) {
        return IERC20Metadata(usdcTokenAddress).decimals();
    }

    function getUSDCTreasuryAllowance() public view returns (uint256) {
        return usdcToken.allowance(owner, address(this));
    }

    function transferUSDCs(address payable _recipient, uint256 _amount)
        internal
        onlyAdmin
        notPaused
        addressNotZero(_recipient)
    {
        usdcToken.transferFrom(owner, _recipient, _amount);
    }

    function transferMATICs(address payable _recipient, uint256 _amount)
        public
        onlyAdmin
        notPaused
        addressNotZero(_recipient)
    {
        payable(_recipient).transfer(_amount);
        emit TransferMatic(_recipient, _amount);
    }

    function setTxFeeUsdc(uint256 _NewtxFeeUsdcWei) external onlyAdmin {
        txFeeUsdc = _NewtxFeeUsdcWei;
        emit TxFeeUsdcChanged(_NewtxFeeUsdcWei);
    }

    function setUsdcTokenAddress(address _usdcTokenAddress)
        external
        addressNotZero(_usdcTokenAddress)
        onlyAdmin
    {
        usdcTokenAddress = _usdcTokenAddress;
        usdcToken = IERC20(_usdcTokenAddress);
        emit UsdcTokenAddressChanged(_usdcTokenAddress);
    }

    function setAdmin(address _newAdmin)
        external
        addressNotZero(_newAdmin)
        onlyAdmin
    {
        owner = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    function setTreasuryAddress(address payable _revenueWallet)
        external
        addressNotZero(_revenueWallet)
        onlyAdmin
    {
        revenueWallet = _revenueWallet;
        emit AdminChanged(_revenueWallet);
    }

    //Possibilidade de mudar a taxa da mentora
    function setTxMentora(uint256 _newbpsTxFeeAmount) external onlyAdmin {
        bpsTxFeeAmount = _newbpsTxFeeAmount;
        emit TxMentoraChanged(_newbpsTxFeeAmount);
    }

    //Pausa e despausa o contrato
    function pauseContract() external onlyAdmin {
        require(!isPaused, "Contract is paused");
        isPaused = true;
        emit PausedContract(true);
    }

    function unpauseContract() external onlyAdmin {
        require(isPaused, "Contract is not paused");
        isPaused = false;
        emit UnPauseContract(true);
    }

    function calculatePercentage(uint256 amount, uint256 bps)
        public
        pure
        returns (uint256)
    {
        // require((amount * bps) >= 10_000, "Wrong percentage");
        return (amount * bps) / 10_000;
    }

    function calculateFeePercentage(uint256 amount)
        public
        view
        returns (uint256)
    {
        return calculatePercentage(amount, bpsTxFeeAmount);
    }

    // todo test for decimals
    function sumUSDCAmountInWei(TransferInfo[] memory _transferInfo)
        public
        pure
        returns (uint256 totalUSDCAmount)
    {
        totalUSDCAmount = 0;

        for (uint256 i = 0; i < _transferInfo.length; i++) {
            totalUSDCAmount += _transferInfo[i].amount;
        }
    }

    // faz o calculo do fee para validação
    function calculateFeeOverAllTransfers(TransferInfo[] memory _transferInfo)
        external
        view
        returns (uint256 totalSum)
    {
        totalSum = 0;

        for (uint256 i = 0; i < _transferInfo.length; i++) {
            totalSum += _transferInfo[i].amount;
        }
        return calculateFeePercentage(totalSum);
    }

    function convertWeiToUSDCAmount(uint256 amount)
        public
        pure
        returns (uint256)
    {
        // uint256 decimals = getUSDCDecimals();

        return (amount * (10**6)) / 1e18;
    }

    //Realiza transferência a varias wallets
    function multiSender(
        TransferInfo[] calldata _transferInfo,
        uint256 _batchId
    )
        external
        atLeastOneTransfer(_transferInfo)
        batchNotExistent(_batchId)
        notPaused
        onlyAdmin
    {
        transferBatches[_batchId] = TransferBatch({
            batchId: _batchId,
            exists: true
        });

        uint256 totalUSDCAmountToTransfer = sumUSDCAmountInWei(_transferInfo);
        uint256 treasuryAllowance = getUSDCTreasuryAllowance();

        uint256 totalFeeSum = 0;

        require(
            treasuryAllowance >= totalUSDCAmountToTransfer,
            "Not enough allowance"
        );

        //Inicializa o token e transferencias
        for (uint256 i = 0; i < _transferInfo.length; i++) {
            uint256 totalUsdcAmount = _transferInfo[i].amount;
            uint feeUSdc = txFeeUsdc;
            uint256 fee = calculateFeePercentage(totalUsdcAmount);

            address payable recipient = _transferInfo[i].recipient;

            uint256 totalFeeToUser = fee + feeUSdc;

            uint256 amountToTransfer = totalUsdcAmount - totalFeeToUser;

            //send the specified amount to the recipients

            transferUSDCs(recipient, amountToTransfer);
            transferMATICs(recipient, txFeeMaticSendToUser);
            emit TokenTransferCompleted(
                msg.sender,
                recipient,
                amountToTransfer,
                bpsTxFeeAmount,
                fee,
                feeUSdc,
                _batchId
            );

            totalFeeSum += totalFeeToUser;
        }

        //send the specified amount to the treasury
        transferUSDCs(revenueWallet, totalFeeSum);
        emit FeeTransfer(msg.sender, revenueWallet, totalFeeSum, _batchId);
    }

    function getBalanceMatic() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value != 0);
        payable(address(this)).transfer(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}