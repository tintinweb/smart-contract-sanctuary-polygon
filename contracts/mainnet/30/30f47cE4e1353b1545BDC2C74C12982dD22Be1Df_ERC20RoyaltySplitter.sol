// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../utils/ERC20Splitter.sol";

/*
 * @title ERC20RoyaltySplitter
 * @author MAJR, Inc.
 * @notice This contract splits the incoming (received) tokens to the royalty split addresses
 */
contract ERC20RoyaltySplitter is ERC20Splitter {
  /// @notice The name of this royalty splitter contract for reference
  string public nameForReference;

  /**
   * @notice Constructor
   * @param _token address
   * @param _splitAddresses address payable[] memory
   * @param _splitAmounts uint256[] memory
   * @param _referralAddresses address payable[] memory
   * @param _referralAmounts uint256[] memory
   * @param _cap uint256
   * @param _nameForReference string memory
   */
  constructor(
    address _token,
    address[] memory _splitAddresses,
    uint256[] memory _splitAmounts,
    address[] memory _referralAddresses,
    uint256[] memory _referralAmounts,
    uint256 _cap,
    string memory _nameForReference
  )
    ERC20Splitter(
      _token,
      _splitAddresses,
      _splitAmounts,
      _referralAddresses,
      _referralAmounts,
      _cap
    )
  {
    nameForReference = _nameForReference;
  }

  receive() external payable {
    splitRoyalties();

    (bool sent, ) = owner().call{ value: msg.value }("");
    require(
      sent,
      "ERC20RoyaltySplitter: Failed to send the received ether to the owner."
    );
  }

  fallback() external {
    splitRoyalties();
  }

  /**
   * @notice Splits the incoming (received) tokens to the royalty split addresses
   * @dev Contract must have the token balance greater than zero
   */
  function splitRoyalties() public {
    uint256 contractBalance = IERC20(token).balanceOf(address(this));

    require(
      contractBalance > 0,
      "ERC20RoyaltySplitter: No tokens to be split."
    );

    this.split(contractBalance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

/*
 * @title ERC20Splitter
 * @author MAJR, Inc.
 * @notice This contract splits the incoming (received) ERC20 tokens to the split addresses and the referreral addresses
 */
abstract contract ERC20Splitter is Ownable {
  /// @notice Address of the token to be split
  address public token;

  /// @notice Addresses to which the split amounts will be sent
  address[] public splitAddresses;

  /// @notice Amounts to be sent to each corresponding split address (expressed in basis points)
  uint256[] public splitAmounts;

  /// @notice Addresses to which the referral amounts will be sent
  address[] public referralAddresses;

  /// @notice Amounts to be sent to each corresponding referral address (expressed in basis points)
  uint256[] public referralAmounts;

  /// @notice An adjustable cap for the length of the split addresses, split amounts, referral addresses and referral amounts arrays
  uint256 public cap;

  /// @notice An event emitted when tokens get sent to the split addresses
  event Split(address payee, uint256 amount);

  /// @notice An event emitted when tokens get sent to the referrer's address
  event Referral(address payee, uint256 amount);

  /// @notice An event emitted when the split addresses and amounts are updated
  event SplitUpdated(address[] addresses, uint256[] amounts);

  /// @notice An event emitted when the referral addresses and amounts are updated
  event ReferralUpdated(address[] addresses, uint256[] amounts);

  /// @notice An event emitted when the cap is updated
  event CapUpdated(uint256 cap);

  /**
   * @notice Constructor
   * @param _token address
   * @param _splitAddresses address[] memory
   * @param _splitAmounts uint256[] memory
   * @param _referralAddresses address[] memory
   * @param _referralAmounts uint256[] memory
   */
  constructor(
    address _token,
    address[] memory _splitAddresses,
    uint256[] memory _splitAmounts,
    address[] memory _referralAddresses,
    uint256[] memory _referralAmounts,
    uint256 _cap
  ) {
    token = _token;
    cap = _cap;
    setSplit(_splitAddresses, _splitAmounts);
    setReferral(_referralAddresses, _referralAmounts);
  }

  /**
   * @notice Sends the mint fee to the split addresses
   * @param _splitAmount uint256
   * @dev Split amount can't be zero
   */
  function split(uint256 _splitAmount) external {
    require(_splitAmount > 0, "Splitter: Invalid split amount.");

    bool approved = IERC20(token).approve(address(this), _splitAmount);
    require(
      approved,
      "Splitter: Couldn't approve tokens for spending by the contract."
    );

    for (uint i = 0; i < splitAddresses.length; i++) {
      uint256 amount = (_splitAmount * splitAmounts[i]) / 10000;
      bool sent = IERC20(token).transferFrom(
        msg.sender,
        splitAddresses[i],
        amount
      );
      require(sent, "Splitter: Couldn't send tokens to you.");
      emit Split(splitAddresses[i], amount);
    }
  }

  /**
   * @notice Sends the mint fee to the referral addresses
   * @param _splitAmount uint256
   * @param referrer address
   * @dev Referrer address can't be zero address
   * @dev Split amount can't be zero
   */
  function referralSplit(uint256 _splitAmount, address referrer) external {
    require(_splitAmount > 0, "Splitter: Invalid split amount.");
    require(address(0) != referrer, "Splitter: Invalid referrer address.");

    bool approved = IERC20(token).approve(address(this), _splitAmount);
    require(
      approved,
      "Splitter: Couldn't approve tokens for spending by the contract."
    );

    for (uint i = 0; i < referralAddresses.length; i++) {
      uint256 amount = (IERC20(token).balanceOf(address(this)) *
        referralAmounts[i]) / 10000;
      if (referralAddresses[i] == address(0)) {
        bool sent = IERC20(token).transferFrom(msg.sender, referrer, amount);
        require(sent, "Splitter: Couldn't send tokens to you.");
        emit Referral(referrer, amount);
      } else {
        bool sent = IERC20(token).transferFrom(
          msg.sender,
          referralAddresses[i],
          amount
        );
        require(sent, "Splitter: Couldn't send tokens to you.");
        emit Split(referralAddresses[i], amount);
      }
    }
  }

  /**
   * @notice Returns the split addresses
   * @return address[] memory
   */
  function getSplitAddresses() external view returns (address[] memory) {
    return splitAddresses;
  }

  /**
   * @notice Returns the split amounts (expressed in basis points)
   * @return uint256[] memory
   */
  function getSplitAmounts() external view returns (uint256[] memory) {
    return splitAmounts;
  }

  /**
   * @notice Sets the split addresses and amounts (expressed in basis points)
   * @notice The arrays must have the same length, both lengths must be less than `cap`
   * @notice There can't be any zero addresses
   * @notice Split amounts must total 10000 (i.e. 100%)
   * @param _splitAddresses address[] memory
   * @param _splitAmounts uint256[] memory
   * @dev Only owner can call it
   */
  function setSplit(
    address[] memory _splitAddresses,
    uint256[] memory _splitAmounts
  ) public onlyOwner {
    require(
      _splitAddresses.length < cap,
      "Splitter: _splitAddresses length must be less than the cap."
    );
    require(
      _splitAddresses.length == _splitAmounts.length,
      "Splitter: _splitAddresses and _splitAmounts must be the same length."
    );
    require(
      _getSum(_splitAmounts) == 10000,
      "Splitter: _splitAmounts must total 10000."
    );
    require(
      _checkForInvalidAddress(_splitAddresses),
      "Splitter: _splitAddresses contains an invalid address(0)."
    );

    splitAddresses = _splitAddresses;
    splitAmounts = _splitAmounts;

    emit SplitUpdated(_splitAddresses, _splitAmounts);
  }

  /**
   * @notice Returns the referral addresses
   * @return address[] memory
   */
  function getReferralAddresses() external view returns (address[] memory) {
    return referralAddresses;
  }

  /**
   * @notice Returns the referral amounts (expressed in basis points)
   * @return uint256[] memory
   */
  function getReferralAmounts() external view returns (uint256[] memory) {
    return referralAmounts;
  }

  /**
   * @notice Sets the referral addresses and amounts (expressed in basis points)
   * @notice The arrays must have the same length, both lengths must be less than 5
   * @notice There must be at least one zero address (it later gets replaced by the referrer's address)
   * @notice Referral amounts must total 10000 (i.e. 100%)
   * @param _referralAddresses address[] memory
   * @param _referralAmounts uint256[] memory
   * @dev Only owner can call it
   */
  function setReferral(
    address[] memory _referralAddresses,
    uint256[] memory _referralAmounts
  ) public onlyOwner {
    require(
      _referralAddresses.length < cap + 1,
      "Splitter: _referralAddresses length must be less than the cap + 1."
    );
    require(
      _referralAddresses.length == _referralAmounts.length,
      "Splitter: _referralAddresses and _referralAmounts must be the same length."
    );
    require(
      _getSum(_referralAmounts) == 10000,
      "Splitter: _referralAmounts must total 10000."
    );
    require(
      _checkForReferralAddress(_referralAddresses),
      "Splitter: Must pass zero address as one of the addresses in the array."
    );

    referralAddresses = _referralAddresses;
    referralAmounts = _referralAmounts;

    emit ReferralUpdated(_referralAddresses, _referralAmounts);
  }

  /**
   * @notice Sets the cap for the length of the split addresses, split amounts, referral addresses and referral amounts arrays
   * @param _cap uint256
   * @dev Only owner can call it
   */
  function setCap(uint256 _cap) external onlyOwner {
    require(_cap >= 4, "Splitter: Cap must be greater than or equal to 4.");

    cap = _cap;

    emit CapUpdated(_cap);
  }

  /**
   * @notice Returns whether the given array of addresses contains an address to be later replaced with the referral address (i.e. zero address) or not
   * @param _referralAddresses address[] memory
   * @return bool
   * @dev There can be only one zero address in the array
   */
  function _checkForReferralAddress(
    address[] memory _referralAddresses
  ) private pure returns (bool) {
    bool valid = false;

    for (uint i = 0; i < _referralAddresses.length; i++) {
      if (_referralAddresses[i] == address(0)) {
        if (valid) {
          return false;
        }
        valid = true;
      }
    }

    return valid;
  }

  /**
   * @notice Returns whether the given array of addresses is a valid array of split addresses or not (i.e. it should not contain the zero address)
   * @param _referralAddresses address[] memory
   * @return bool
   */
  function _checkForInvalidAddress(
    address[] memory _referralAddresses
  ) private pure returns (bool) {
    bool valid = true;

    for (uint i = 0; i < _referralAddresses.length; i++) {
      if (_referralAddresses[i] == address(0)) {
        valid = false;
      }
    }

    return valid;
  }

  /**
   * @notice Returns sum of the given array of integer values
   * @param input uint256[] memory
   * @return uint256
   */
  function _getSum(uint256[] memory input) private pure returns (uint256) {
    uint256 sum = 0;

    for (uint i = 0; i < input.length; i++) {
      sum = sum + input[i];
    }

    return sum;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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