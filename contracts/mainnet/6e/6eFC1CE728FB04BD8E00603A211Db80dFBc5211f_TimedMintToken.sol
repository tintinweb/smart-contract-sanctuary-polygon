//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./AccessControl.sol";
import "./ERC20TimedMint.sol";
import "./MerkleProof.sol";
import "./Airdroppable.sol";

//import "./console.sol";

/**
 * @title Timed Mint Token
 * @author Javier Gonzalez
 * @notice Scheduled On-Chain Token Distribution
 */
contract TimedMintToken is ERC20TimedMint, AccessControl, Airdroppable {
    uint256 public immutable initialSupply;
    address public vault;
    address public minter;

    event VaultUpdated(address oldVault, address newVault);
    event NewMintGuard(uint256 nextAllowedMintTime, uint256 maxMintAmount);
    event MinterUpdated(address oldMinter, address newMinter);

    /**
     * @notice Launches contract, mints tokens for a vault and for an airdrop
     * @param _freeSupply The number of tokens to issue to the contract deployer
     * @param _airdropSupply The number of tokens to reserve for the airdrop
     * @param _totalSupplyCap The max number of tokens that can be minted, if zero then the cap is ignored
     * @param _vault The address to send the free supply to
     * @param _timeDelay how many seconds should span until user can mint again
     * @param _mintCap how many coins can be minted each minting period
     * @param name The ERC20 token name
     * @param symbol The ERC20 token symbol
     * @param admins A list of addresses that are able to call admin functions
     */
    constructor(
        uint256 _freeSupply,
        uint256 _airdropSupply,
        uint256 _totalSupplyCap,
        address _vault,
        uint256 _timeDelay,
        uint256 _mintCap,
        string memory name,
        string memory symbol,
        address[] memory admins
    ) ERC20TimedMint(_totalSupplyCap, name, symbol) {
        _mint(_vault, _freeSupply);
        _mint(address(this), _airdropSupply);
        initialSupply = _freeSupply + _airdropSupply;
        _setMintGuard(_timeDelay, _mintCap);
        _updateVault(_vault);
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function getInitialSupply() public view returns (uint256) {
        return initialSupply;
    }

    /**
     * @dev Sets vault to a new address
     * @param _vault Address which will be the recipient of new mints
     */
    function _updateVault(address _vault) internal {
        address oldVault = vault;
        vault = _vault;
        emit VaultUpdated(oldVault, vault);
    }

    /**
     * @notice Updates vault to new address
     * @param _vault Address which will be the recipient of new mints
     */
    function updateVault(address _vault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateVault(_vault);
    }

    /**
     * @dev Set timeDelay and mintCap at once
     * @param _timeDelay Seconds until next allowable mint
     * @param _mintCap Maximum allowed mint amount
     */
    function _setMintGuard(uint256 _timeDelay, uint256 _mintCap) internal {
        _setTimeDelay(_timeDelay);
        _setMintCap(_mintCap);
        emit NewMintGuard(nextAllowedMintTime, _mintCap);
    }

    /**
     * @notice Sets a time delay for the minting function
     * @param _timeDelay Seconds until next allowable mint
     * @param _mintCap Maximum allowed mint amount
     */
    function setMintGuard(uint256 _timeDelay, uint256 _mintCap)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyAfterTimeDelay
    {
        _setMintGuard(_timeDelay, _mintCap);
    }

    /**
     * @notice mints tokens to the vault address
     * @dev requires minter role to call this function
     * @param amount Number of tokens to send to the vault
     */
    function mint(uint256 amount) public onlyMinter {
        _mint(vault, amount);
    }

    /**
     * @notice Sets minter role
     * @dev only admin can update the minter
     * @param newMinter new Minter address
     */
    function setMinter(address newMinter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldMinter = minter;
        minter = newMinter;
        emit MinterUpdated(oldMinter, newMinter);
    }

    function newAirdrop(bytes32 _merkleRoot, uint256 _timeLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256 airdropId)
    {
        return _newAirdrop(_merkleRoot, _timeLimit);
    }

    function completeAirdrop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _completeAirdrop();
    }

    function sweepTokens(address _destination)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _sweepTokens(_destination, balanceOf(address(this)));
    }

    function _sweep(address to, uint256 amount) internal virtual override {
        _transfer(address(this), to, amount);
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Only Minter can call");
        _;
    }
}