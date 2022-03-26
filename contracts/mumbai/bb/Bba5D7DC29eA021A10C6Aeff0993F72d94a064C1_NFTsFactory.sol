// SPDX-License-Identifier: MIT
// File: Quest/Interfaces/INFTsFactory.sol

pragma solidity ^0.8.10;

import "./Initializable.sol"; 
import "./ContextUpgradeable.sol";
import "./UUPSUpgradeable.sol"; 
import "./ERC1967Proxy.sol";
import "./AddressUpgradeable.sol";
import "./NFTs.sol";

interface INFTsFactory {

    event proxyDeployed(address indexed propContractAddr);

    function __NFTsFactory_init() external;

    function deployTokens(
        string calldata uri_,  
        address assetWallet,
        address hoa,
        address treasury, 
        string calldata _contractName, 
        uint256 propTaxId
    ) external returns(address);

    function assetContractAddress(address assetWallet) external view returns(address);

    function numOfAssets() external view returns(uint256);

    function allAssets() external view returns(address[] calldata);

    function isPaused() external view returns(bool);
}

// File: Quest/Security/PausableUpgradeable.sol
pragma solidity ^0.8.10;

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {

    event Paused(address account);

    event Unpaused(address account);

    bool internal _paused;

    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    function paused() internal view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}


// File: Quest/Access/OwnableUpgradeable.sol
pragma solidity ^0.8.0;

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}


// File: Quest/NFTsFactory.sol
pragma solidity ^0.8.0;

contract NFTsFactory is Initializable, INFTsFactory, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

  using AddressUpgradeable for address;

  //Implementation address
  address NFTsAddress;

  //Iterable proxy mapping
  mapping(address=> address) internal assetsMap;
  address[] internal assets;

  function __NFTsFactory_init() public virtual override initializer {
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
    NFTsAddress = address(new NFTs());
  }

  function deployTokens(
    string memory uri_,
    address assetWallet,
    address hoa,
    address treasury, 
    string memory _contractName, 
    uint256 propTaxId
  ) public virtual whenNotPaused returns(address){
      ERC1967Proxy proxy = new ERC1967Proxy(NFTsAddress, abi.encodeWithSelector(NFTs(address(0)).initialize.selector, uri_, assetWallet, hoa, treasury, _contractName, propTaxId));
      _transferOwnership(hoa);
      
      address assetAddress = address(proxy);
      assetsMap[assetWallet] = assetAddress;
      assets.push(assetAddress);

      emit proxyDeployed(assetAddress);

      return (assetAddress);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function isPaused() external view override returns(bool){
    return _paused;
  }

  function assetContractAddress(address assetWallet) external view virtual override returns(address) {
    return assetsMap[assetWallet];
  }

  function numOfAssets() external view virtual override returns(uint256) {
    return uint256(assets.length);
  }

  function allAssets() external view virtual override returns(address[] memory) {
    return assets;
  }

  function _authorizeUpgrade(address newFactory) internal virtual override onlyOwner {
    require(AddressUpgradeable.isContract(newFactory), "NFTsFactory: new factory must be a contract");
    require(newFactory != address(0), "NFTsFactory: set to the zero address");
  }
}