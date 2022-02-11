pragma solidity >=0.6.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

contract PolkabridgeLaunchPadV2 is Ownable, ReentrancyGuard {
    string public name = "PolkaBridge: LaunchPad V2";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    address payable private ReceiveToken;

    struct IDOPool {
        uint256 Id;
        uint256 Begin;
        uint256 End;
        uint256 Type; //1: comminity round, 2 stackers round
        IERC20 IDOToken;
        uint256 MaxPurchaseTier1;
        uint256 MaxPurchaseTier2; //==comminity tier
        uint256 MaxPurchaseTier3;
        uint256 TotalCap;
        uint256 MinimumTokenSoldout;
        uint256 TotalToken; //total sale token for this pool
        uint256 RatePerETH;
        uint256 TotalSold; //total number of token sold
        uint256 MinimumStakeAmount;
    }

    struct ClaimInfo {
        uint256 ClaimTime1;
        uint256 PercentClaim1;
        uint256 ClaimTime2;
        uint256 PercentClaim2;
        uint256 ClaimTime3;
        uint256 PercentClaim3;
    }

    struct User {
        uint256 Id;
        address UserAddress;
        bool IsWhitelist;
        uint256 TotalTokenPurchase;
        uint256 TotalETHPurchase;
        uint256 PurchaseTime;
        uint256 LastClaimed;
        uint256 TotalPercentClaimed;
        uint256 NumberClaimed;
        bool IsActived;
    }

    mapping(uint256 => mapping(address => User)) public users; //poolid - listuser

    IDOPool[] pools;

    mapping(uint256 => ClaimInfo) public claimInfos; //pid

    constructor(address payable receiveTokenAdd) public {
        ReceiveToken = receiveTokenAdd;
    }

    function addMulWhitelist(address[] memory user, uint256 pid)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < user.length; i++) {
            users[pid][user[i]].Id = pid;
            users[pid][user[i]].UserAddress = user[i];
            users[pid][user[i]].IsWhitelist = true;
            users[pid][user[i]].IsActived = true;
        }
    }

    function updateWhitelist(
        address user,
        uint256 pid,
        bool isWhitelist,
        bool isActived
    ) public onlyOwner {
        users[pid][user].IsWhitelist = isWhitelist;
        users[pid][user].IsActived = isActived;
    }

    function IsWhitelist(
        address user,
        uint256 pid,
        uint256 stackAmount
    ) public view returns (bool) {
        uint256 poolIndex = pid.sub(1);
        if (pools[poolIndex].Type == 1) // community round
        {
            return true;
        } else if (pools[poolIndex].Type == 2) // stakers round
        {
            if (stackAmount >= pools[poolIndex].MinimumStakeAmount) return true;
            return false;
        } else if (pools[poolIndex].Type == 3) //internal
        {
            if (users[poolIndex][user].IsWhitelist) return true;
            return false;
        } else {
            return false;
        }
    }

    function addPool(
        uint256 begin,
        uint256 end,
        uint256 _type,
        IERC20 idoToken,
        uint256 maxPurchaseTier1,
        uint256 maxPurchaseTier2,
        uint256 maxPurchaseTier3,
        uint256 totalCap,
        uint256 totalToken,
        uint256 ratePerETH,
        uint256 minimumTokenSoldout,
        uint256 minimumStakeAmount
    ) public onlyOwner {
        uint256 id = pools.length.add(1);
        pools.push(
            IDOPool({
                Id: id,
                Begin: begin,
                End: end,
                Type: _type,
                IDOToken: idoToken,
                MaxPurchaseTier1: maxPurchaseTier1,
                MaxPurchaseTier2: maxPurchaseTier2,
                MaxPurchaseTier3: maxPurchaseTier3,
                TotalCap: totalCap,
                TotalToken: totalToken,
                RatePerETH: ratePerETH,
                TotalSold: 0,
                MinimumTokenSoldout: minimumTokenSoldout,
                MinimumStakeAmount: minimumStakeAmount
            })
        );
    }

    function addClaimInfo(
        uint256 percentClaim1,
        uint256 claimTime1,
        uint256 percentClaim2,
        uint256 claimTime2,
        uint256 percentClaim3,
        uint256 claimTime3,
        uint256 pid
    ) public onlyOwner {
        claimInfos[pid].ClaimTime1 = claimTime1;
        claimInfos[pid].PercentClaim1 = percentClaim1;
        claimInfos[pid].ClaimTime2 = claimTime2;
        claimInfos[pid].PercentClaim2 = percentClaim2;
        claimInfos[pid].ClaimTime3 = claimTime3;
        claimInfos[pid].PercentClaim3 = percentClaim3;
    }

    function updateClaimInfo(
        uint256 percentClaim1,
        uint256 claimTime1,
        uint256 percentClaim2,
        uint256 claimTime2,
        uint256 percentClaim3,
        uint256 claimTime3,
        uint256 pid
    ) public onlyOwner {
        if (claimTime1 > 0) {
            claimInfos[pid].ClaimTime1 = claimTime1;
        }

        if (percentClaim1 > 0) {
            claimInfos[pid].PercentClaim1 = percentClaim1;
        }
        if (claimTime2 > 0) {
            claimInfos[pid].ClaimTime2 = claimTime2;
        }

        if (percentClaim2 > 0) {
            claimInfos[pid].PercentClaim2 = percentClaim2;
        }

        if (claimTime3 > 0) {
            claimInfos[pid].ClaimTime3 = claimTime3;
        }

        if (percentClaim3 > 0) {
            claimInfos[pid].PercentClaim3 = percentClaim3;
        }
    }

    function updatePool(
        uint256 pid,
        uint256 begin,
        uint256 end,
        uint256 maxPurchaseTier1,
        uint256 maxPurchaseTier2,
        uint256 maxPurchaseTier3,
        uint256 totalCap,
        uint256 totalToken,
        uint256 ratePerETH,
        IERC20 idoToken,
        uint256 minimumTokenSoldout,
        uint256 pooltype,
        uint256 minimumStakeAmount
    ) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        if (begin > 0) {
            pools[poolIndex].Begin = begin;
        }
        if (end > 0) {
            pools[poolIndex].End = end;
        }

        if (maxPurchaseTier1 > 0) {
            pools[poolIndex].MaxPurchaseTier1 = maxPurchaseTier1;
        }
        if (maxPurchaseTier2 > 0) {
            pools[poolIndex].MaxPurchaseTier2 = maxPurchaseTier2;
        }
        if (maxPurchaseTier3 > 0) {
            pools[poolIndex].MaxPurchaseTier3 = maxPurchaseTier3;
        }
        if (totalCap > 0) {
            pools[poolIndex].TotalCap = totalCap;
        }
        if (totalToken > 0) {
            pools[poolIndex].TotalToken = totalToken;
        }
        if (ratePerETH > 0) {
            pools[poolIndex].RatePerETH = ratePerETH;
        }

        if (minimumStakeAmount > 0) {
            pools[poolIndex].MinimumStakeAmount = minimumStakeAmount;
        }

        if (minimumTokenSoldout > 0) {
            pools[poolIndex].MinimumTokenSoldout = minimumTokenSoldout;
        }
        if (pooltype > 0) {
            pools[poolIndex].Type = pooltype;
        }
        pools[poolIndex].IDOToken = idoToken;
    }

    function withdrawErc20(IERC20 token) public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    //withdraw ETH after IDO
    function withdrawPoolFund() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        ReceiveToken.transfer(balance);
    }

    function purchaseIDO(
        uint256 stakeAmount,
        uint256 pid,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        uint256 poolIndex = pid.sub(1);

        if (pools[poolIndex].Type == 2) {
            bytes32 _hash = keccak256(abi.encodePacked(msg.sender, stakeAmount));
            bytes32 messageHash = _hash.toEthSignedMessageHash();

            require(
                owner() == ecrecover(messageHash, v, r, s),
                "owner should sign purchase info"
            );
        }

        require(
            block.timestamp >= pools[poolIndex].Begin &&
                block.timestamp <= pools[poolIndex].End,
            "invalid time"
        );
        //check user
        require(IsWhitelist(msg.sender, pid, stakeAmount), "invalid user");

        //check amount
        uint256 ethAmount = msg.value;
        users[pid][msg.sender].TotalETHPurchase = users[pid][msg.sender]
            .TotalETHPurchase
            .add(ethAmount);

        if (pools[poolIndex].Type == 2) {
            //stackers round
            if (stakeAmount < 1500 * 1e18) {
                require(
                    users[pid][msg.sender].TotalETHPurchase <=
                        pools[poolIndex].MaxPurchaseTier1,
                    "invalid maximum purchase for tier1"
                );
            } else if (
                stakeAmount >= 1500 * 1e18 && stakeAmount < 3000 * 1e18
            ) {
                require(
                    users[pid][msg.sender].TotalETHPurchase <=
                        pools[poolIndex].MaxPurchaseTier2,
                    "invalid maximum purchase for tier2"
                );
            } else {
                require(
                    users[pid][msg.sender].TotalETHPurchase <=
                        pools[poolIndex].MaxPurchaseTier3,
                    "invalid maximum purchase for tier3"
                );
            }
        } else if (pools[poolIndex].Type == 1) {
            //community round

            require(
                users[pid][msg.sender].TotalETHPurchase <=
                    pools[poolIndex].MaxPurchaseTier2,
                "invalid maximum contribute"
            );
        } else {
            //=3
            require(
                users[pid][msg.sender].TotalETHPurchase <=
                    pools[poolIndex].MaxPurchaseTier3,
                "invalid maximum contribute"
            );
        }

        uint256 tokenAmount = ethAmount.mul(pools[poolIndex].RatePerETH).div(
            1e18
        );

        uint256 remainToken = getRemainIDOToken(pid);
        require(
            remainToken > pools[poolIndex].MinimumTokenSoldout,
            "IDO sold out"
        );
        require(remainToken >= tokenAmount, "IDO sold out");

        users[pid][msg.sender].TotalTokenPurchase = users[pid][msg.sender]
            .TotalTokenPurchase
            .add(tokenAmount);

        pools[poolIndex].TotalSold = pools[poolIndex].TotalSold.add(
            tokenAmount
        );
    }

    function claimToken(uint256 pid) public nonReentrant {
        require(
            users[pid][msg.sender].TotalPercentClaimed < 100,
            "you have claimed enough"
        );
        uint256 userBalance = getUserTotalPurchase(pid);
        require(userBalance > 0, "invalid claim");

        uint256 poolIndex = pid.sub(1);
        if (users[pid][msg.sender].NumberClaimed == 0) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime1,
                "invalid time"
            );
            pools[poolIndex].IDOToken.safeTransfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim1).div(100)
            );
          users[pid][msg.sender].TotalPercentClaimed=  users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim1
            );
        } else if (users[pid][msg.sender].NumberClaimed == 1) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime2,
                "invalid time"
            );
            pools[poolIndex].IDOToken.safeTransfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim2).div(100)
            );
            users[pid][msg.sender].TotalPercentClaimed=users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim2
            );
        } else if (users[pid][msg.sender].NumberClaimed == 2) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime3,
                "invalid time"
            );
            pools[poolIndex].IDOToken.safeTransfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim3).div(100)
            );
           users[pid][msg.sender].TotalPercentClaimed= users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim3
            );
        }

        users[pid][msg.sender].LastClaimed = block.timestamp;
        users[pid][msg.sender].NumberClaimed=users[pid][msg.sender].NumberClaimed.add(1);
    }

    function getUserTotalPurchase(uint256 pid) public view returns (uint256) {
        return users[pid][msg.sender].TotalTokenPurchase;
    }

    function getRemainIDOToken(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        uint256 tokenBalance = getBalanceTokenByPoolId(pid);
        if (pools[poolIndex].TotalSold > tokenBalance) {
            return 0;
        }

        return tokenBalance.sub(pools[poolIndex].TotalSold);
    }

    function getBalanceTokenByPoolId(uint256 pid)
        public
        view
        returns (uint256)
    {
        uint256 poolIndex = pid.sub(1);

        return pools[poolIndex].TotalToken;
    }

    function getPoolInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            IERC20
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            pools[poolIndex].Begin,
            pools[poolIndex].End,
            pools[poolIndex].Type,
            pools[poolIndex].RatePerETH,
            pools[poolIndex].TotalSold,
            pools[poolIndex].IDOToken
        );
    }

    function getClaimInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            claimInfos[poolIndex].ClaimTime1,
            claimInfos[poolIndex].PercentClaim1,
            claimInfos[poolIndex].ClaimTime2,
            claimInfos[poolIndex].PercentClaim2,
            claimInfos[poolIndex].ClaimTime3,
            claimInfos[poolIndex].PercentClaim3
        );
    }

    function getPoolSoldInfo(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        return (pools[poolIndex].TotalSold);
    }

    function getWhitelistfo(uint256 pid)
        public
        view
        returns (
            address,
            bool,
            uint256,
            uint256
        )
    {
        return (
            users[pid][msg.sender].UserAddress,
            users[pid][msg.sender].IsWhitelist,
            users[pid][msg.sender].TotalTokenPurchase,
            users[pid][msg.sender].TotalETHPurchase
        );
    }

    function getUserInfo(uint256 pid, address user)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[pid][user].IsWhitelist,
            users[pid][user].TotalTokenPurchase,
            users[pid][user].TotalETHPurchase,
            users[pid][user].TotalPercentClaimed
        );
    }

    
}