pragma solidity ^0.5.0;
/**
 * The Controller is an upgradeable endpoint for controlling Folia.sol
 */

import "./IShadowController.sol";
import "./Ownable.sol";

contract SimpleShadowController is IShadowController, Ownable {

    bool public paused;

    constructor() public {}

    // this function will be replaced by LUX ERC20 logic eventually
    function isLocked(address from, address to, uint256 tokenId) external view returns (bool) {
        return paused;
    }

    function updatePaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
}