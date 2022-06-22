// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IFeeDistributor} from "./interfaces/IFeeDistributor.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract FeeDistributor is ReentrancyGuard
{
   
    address public owner;
    mapping(address => address) public distributors;
    event SET_DISTRIBUTOR_LOG(address feeToken,address distributor);
    event UPDATE_OWNER_LOG(address indexed newOwner);
    event CALIM_LOG(address indexed sender,address indexed feeToken,uint256 amount);

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setOwner(address _newOwner) external onlyOwner{
        owner = _newOwner;
        emit UPDATE_OWNER_LOG(owner);
    }

    constructor() {
        owner = msg.sender;
    }

    function setDistributor(address feeToken,address distributor) external onlyOwner{
        require(feeToken != address(0) && distributor != address(0),"input params not zero address");
        distributors[feeToken] = distributor;
        emit SET_DISTRIBUTOR_LOG(feeToken,distributor);
    }

    function claim(address feeToken,bool isEth) external nonReentrant{
        address distributor = distributors[feeToken];
        require(distributor != address(0),"distributor not exist");
        uint256 amount = IFeeDistributor(distributor).claimProxy(msg.sender,isEth);
        emit CALIM_LOG(msg.sender,feeToken,amount);

    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

interface IFeeDistributor {
    event Distributed(uint256 time, uint256 tokenAmount);

    event Claimed(
        address indexed recipient,
        uint256 amount,
        uint256 claimEpoch,
        uint256 maxEpoch
    );

    function lastDistributeTime() external view returns (uint256);

    function distribute() external;

    function claim(bool weth) external returns (uint256);
    
    function claimProxy(address sender,bool isEth) external returns (uint256);

    function claimable(address _addr) external view returns (uint256);

    function addressesProvider()
        external
        view
        returns (ILendPoolAddressesProvider);

    function bendCollector() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPoolAddressesProvider {
    function getLendPool() external view returns (address);
}