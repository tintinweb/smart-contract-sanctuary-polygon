// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./utils/TrustedForwarderRecipient.sol";
import "./utils/EnumDeclarations.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

contract BloodSacrifice is TrustedForwarderRecipient {
    IERC20Burnable energy;

    mapping(Cult => uint256) public sacrificesForCult;
    mapping(address => uint256) public sacrificesByAddress;

    event BloodSacrificed(address indexed who, Cult cult, uint256 amount);

    constructor(address forwarderAddress, address energyAddress) TrustedForwarderRecipient(forwarderAddress) {
        energy = IERC20Burnable(energyAddress);
    }

    function sacrifice(Cult cult, uint256 amount) public {
        energy.transferFrom(_msgSender(), address(this), amount);

        energy.burn(amount);

        sacrificesForCult[cult] += amount;
        sacrificesByAddress[_msgSender()] += amount;

        emit BloodSacrificed(_msgSender(), cult, amount);
    }

    function getCultStats() public view returns (uint256, uint256, uint256, uint256) {
        return (
            0,
            sacrificesForCult[Cult.Arcane],
            sacrificesForCult[Cult.Astral],
            sacrificesForCult[Cult.Terrene]
        );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TrustedForwarderRecipient is Ownable {
    address internal _trustedForwarder;

    constructor(address forwarderAddress_) {
        _trustedForwarder = forwarderAddress_;
    }

    // ERC2771Context
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function setForwarder(address trustedForwarder_) public onlyOwner {
        _trustedForwarder = trustedForwarder_;
    }

    function versionRecipient() external pure returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: None

pragma solidity ^0.8.7;

// solidity defaults to 0 index value, so we need a None value
// TODO add Power -> Cult mapping

/*
Realm: 1
Aura: 0-2
Composition: 1
Oculus: 1
Accent: 0-1
Conveyence: 1
DominantPower: 1
*/

enum PartType {
  None,
  Oculus,
  Accent,
  Iris,
  Composition,
  Aura,
  Realm,
  Conveyence,
  DominantPower
}

enum Cult {
  None,
  Arcane,
  Astral,
  Terrene,
  Unknown
}

enum Power {
  None,
  Cosmos,
  Divine,
  Chaos,
  Corporeal,
  Mystic,
  Creature,
  Verdure,
  Toxic,
  Dark,
  Inferno,
  Mundane,
  Spirit,
  Aqueous,
  Geological,
  Oblivion,
  Automaton,
  Numerary,
  Alchemy
}

enum Set {
  None,
  Gold,
  Silver,
  Toxic,
  Plant,
  Vapor,
  Techno,
  NeonRainbow,
  Fire,
  Desert,
  Water,
  NeonRed,
  NeonGreen,
  NeonWhite,
  NeonPurple,
  Snek,
  Moon,
  Spider,
  Blood,
  Diamond,
  OG,
  Beast,
  Wood,
  TerraCotta
}

// Parts
enum Accent {
  None,
  Scraped,
  GoldTips,
  SilverTips,
  BlackTips,
  Acid,
  Petals,
  Clouds,
  Eyelettes,
  Mooncrest,
  Crystal,
  Cracked,
  TechMoon,
  RainbowBit,
  Fire,
  Desert,
  Ocean,
  Asteroids,
  Sash,
  Stole,
  Comet,
  RedBit,
  GreenBit,
  WhiteBit,
  PurpleBit,
  Snek,
  Moon,
  Bandaged,
  Web,
  Blood,
  Bubbles,
  BrokenMoon
}

enum Iris {
  None,
  Grass,
  Moss,
  Aqua,
  Chocolate,
  Hide,
  Sand,
  Ice,
  Sky,
  Deep,
  Blood,
  Rust,
  Violet,
  Dusk
}

enum Aura {
  None,
  RedNova,
  DiamondChips,
  Splatter,
  Steam,
  DotSwarm,
  Eyes,
  Comets,
  Burst,
  TwinMoons,
  NeonRainbow,
  Stardust,
  Siblings,
  VHSet,
  Pulse,
  Miasma,
  Mouflon,
  GoldHalo,
  SilverHalo,
  Moon,
  Volumetrix,
  NeonGreen,
  NeonWhite,
  NeonPurple,
  NeonRed,
  Psych,
  Northstar,
  HaloOfTears,
  Blackhole,
  GoldDust,
  ShatteredGlass
}

enum Composition {
  None,
  Bricked,
  Origami,
  Lava,
  Wet,
  Wooden,
  Grid,
  Alien,
  Speckled,
  Snek,
  Stacked,
  Sandy,
  Swirled,
  BlackMarble,
  Techno,
  Fur,
  Lush,
  NeonRainbow,
  Sliced,
  Mod,
  NeonRed,
  NeonGreen,
  NeonWhite,
  NeonPurple,
  TerraCotta,
  Silver,
  Golden,
  Stone,
  Marble,
  Glowing,
  Pillowed
}

enum Oculus {
  None,
  Quirk,
  Increate,
  Sorrowful,
  Tormented,
  Inset,
  Joyous,
  Pop,
  Snek,
  RainbowBeam,
  Negative,
  Empty,
  Diamond,
  Ruby,
  Emerald,
  Triplet,
  Arachnid,
  Lotus,
  Goat,
  Wiggle,
  Passionate,
  ThirdEye,
  Golden,
  Sapphire,
  WhiteBeam,
  PurpleBeam,
  RedBeam,
  GreenBeam,
  Blotted,
  Acrimonious,
  Toxic,
  BlackPearl,
  Wood,
  TerraCotta,
  Silver,
  Pearl
}

enum Realm {
  None,
  Space,
  Cloudrise,
  Dusk,
  Bluesky,
  Tempzone,
  Network,
  MagWaves,
  Dank,
  Lush,
  Aurora,
  Modworld,
  NotTron,
  VibeWorld,
  Hearth,
  DigiSpectrum,
  Metaverse,
  TriGrid,
  Nightcast,
  GravitysEdge,
  Tunnel,
  Setzone,
  QuadGrid
}

// FIXME fill out remaining values
enum Conveyence {
  None,
  Orbit,
  Sway
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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