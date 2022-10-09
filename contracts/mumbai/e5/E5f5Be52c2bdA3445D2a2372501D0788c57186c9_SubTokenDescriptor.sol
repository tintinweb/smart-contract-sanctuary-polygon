// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../plans/IPlanManager.sol";
import "../merchants/IMerchantToken.sol";
import "./ISubInfoManager.sol";
import "../libs/SubscriptionNFTSVG.sol";
import "../libs/Period.sol";
import "../libs/DecimalToString.sol";
import "./ISubTokenDescriptor.sol";
import {BokkyPooBahsDateTimeLibrary as TimeLib} from "../libs/BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SubTokenDescriptor is ISubTokenDescriptor {


    function tokenURI(address merchantToken, address planManager, address subInfoManager, uint256 tokenId) external view override returns (string memory) {

        // get sub info
        ISubInfoManager.SubInfo memory subInfo = ISubInfoManager(subInfoManager).getSubInfo(tokenId);

        // get plan info
        IPlanManager.Plan memory plan = IPlanManager(planManager).getPlan(subInfo.merchantTokenId, subInfo.planIndex);

        IMerchantToken.Merchant memory merchant = IMerchantToken(merchantToken).getMerchant(subInfo.merchantTokenId);

        string memory paymentTokenName = IERC20Metadata(plan.paymentToken).name();
        string memory paymentTokenSymbol = IERC20Metadata(plan.paymentToken).symbol();

        SubscriptionNFTSVG.SVGParams memory svgParams =
        SubscriptionNFTSVG.SVGParams({
        merchantCode : subInfo.merchantTokenId,
        merchantName : merchant.name,
        planName : plan.name,
        planPeriod : Period.getPeriodName(plan.billingPeriod),
        paymentTokenName : paymentTokenName,
        paymentTokenSymbol : paymentTokenSymbol,
        payeeAddress : Strings.toHexString(uint160(plan.payeeAddress), 20),
        // sub info
        startDateTime : Period.convertTimestampToDateTimeString(subInfo.subStartTime),
        endDateTime : Period.convertTimestampToDateTimeString(subInfo.subEndTime),
        nextBillDateTime : Period.convertTimestampToDateTimeString(subInfo.nextBillingTime),
        price : DecimalToString.decimalString(plan.pricePerBillingPeriod, 18, false)
        });

        string memory image = SubscriptionNFTSVG.generateSVG(svgParams);

        string memory json;
        json = '{"name": "S10N Subscription Token", "description": "This NFT represents a subscription in S10N protocol. The owner of this NFT can cancel this subscription",';
        json = string(abi.encodePacked(json, '"image": "', image, '"'));

        json = string(abi.encodePacked(json, ', "attributes": ['));
        json = string(abi.encodePacked(json, '{"trait_type": "merchant_name", "value": "', merchant.name, '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "merchant_token_id", "value": "', Strings.toString(subInfo.merchantTokenId), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "plan_name", "value": "', plan.name, '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "plan_desc", "value": "', plan.description, '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "plan_billing_period", "value": "', Strings.toString(uint256(plan.billingPeriod)), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "payment_token", "value": "', Strings.toHexString(uint256(uint160(plan.paymentToken)), 20), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "payee_address", "value": "', Strings.toHexString(uint256(uint160(plan.payeeAddress)), 20), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "price_per_billing_period", "value": "', Strings.toString(plan.pricePerBillingPeriod), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "plan_enabled", "value": "', booleanToString(plan.enabled), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "is_SBT", "value": "', booleanToString(plan.isSBT), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "subscription_start_time", "value": "', Strings.toString(subInfo.subStartTime), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "subscription_end_time", "value": "', Strings.toString(subInfo.subEndTime), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "next_billing_time", "value": "', Strings.toString(subInfo.nextBillingTime), '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "subscription_enabled", "value": "', booleanToString(subInfo.enabled), '"}'));
        json = string(abi.encodePacked(json, ']'));

        json = string(abi.encodePacked(json, '}'));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
* @dev Converts an address to a string.
     */
    function addressToString(address _address)
    internal
    pure
    returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes16 alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(str);
    }

    function booleanToString(bool _bool) internal pure returns (string memory) {
        return _bool ? "true" : "false";
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../libs/Period.sol";

interface IPlanManager {

    struct Plan {
        uint256 merchantTokenId;
        string name;
        string description; // plan description
        Period.PeriodType billingPeriod; // Billing Period [DAY, WEEK, MONTH, YEAR]
        address paymentToken;
        address payeeAddress;
        uint256 pricePerBillingPeriod;
        uint maxTermLength; // by month
        bool enabled;
        bool isSBT;
        bool canResubscribe;
    }

    function setManager(address _manager) external;

//    function createPlan(
//        uint256 merchantTokenId,
//        string memory name,
//        string memory description,
//        Period.PeriodType billingPeriod,
//        address paymentToken,
//        address payeeAddress,
//        uint256 pricePerBillingPeriod,
//        bool isSBT,
//        uint maxTermLength,
//        bool canResubscribe
//    ) external returns (uint planIndex);

    function createPlan(Plan memory plan) external returns (uint planIndex);

//    function updatePlan(
//        uint256 merchantTokenId,
//        uint256 planIndex,
//        string memory name,
//        string memory description,
//        address payeeAddress
//    ) external;

    function updatePlan(
        uint256 merchantTokenId,
        uint256 planIndex,
        Plan memory plan
    ) external;

    function getPlan(uint256 merchant, uint256 planIndex)
    external
    view
    returns (
        Plan memory plan
    );

    function getPlans(uint256 merchant)
    external
    view
    returns (
        Plan[] memory plans
    );

//    function disablePlan(uint256 merchant, uint256 planIndex) external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IMerchantToken is IERC721EnumerableUpgradeable {

    struct Merchant {
        string name;
    }

    function setManager(address manager) external;

    function createMerchant(string memory name, address merchantOwner) external returns (uint);

    function updateMerchant(uint merchantTokenId, string memory name) external;

//    function getMerchantInfo(uint tokenId) external view returns (string memory name, address owner, address payee);

    function getMerchant(uint merchantTokenId) external view returns (Merchant memory merchant);

    function setMerchantTokenDescriptor(address descriptor) external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ISubInfoManager {
    struct SubInfo {
        uint256 merchantTokenId;
        uint256 subTokenId;
        uint256 planIndex; // plan Index (name?)
        uint256 subStartTime; // sub valid start time subStartTime
        uint256 subEndTime; // sub valid end time subEndTime
        uint256 nextBillingTime; // next bill time nextBillingTime
        bool enabled; // if sub valid
    }

    function setManager(address _manager) external;

    function createSubInfo(
        uint256 merchantTokenId,
        uint256 subTokenId,
        uint256 planIndex,
        uint256 subStartTime,
        uint256 subEndTime,
        uint256 nextBillingTime
    ) external;

    function getSubInfo(uint256 subTokenId)
        external
        view
        returns (SubInfo memory subInfo);

    function updateSubInfo(
        uint256 merchantTokenId,
        uint256 tokenId,
        SubInfo memory subInfo
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libs/Base64.sol";

/// @title NFTSVG
library SubscriptionNFTSVG {
    using Strings for uint256;

    struct SVGParams {
        // merchant info
        uint256 merchantCode;
        string merchantName;
        // plan info
        string planName;
        string planPeriod;
        string paymentTokenName;
        string paymentTokenSymbol;
        string payeeAddress;
        // sub info
        string startDateTime;
        string endDateTime;
        string nextBillDateTime;
        //        string termDateTime;
        string price;
    }

    function generateSVG(SVGParams memory params)
    internal
    pure
    returns (string memory svg)
    {
        string memory meta = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.dev/svgjs" width="800" height="800" viewBox="0 0 800 800" style="background-color:black">',
                '<defs>',
                '<path id="text-path-a" d="M100 55 H700 A45 45 0 0 1 745 100 V700 A45 45 0 0 1 700 745 H100 A45 45 0 0 1 55 700 V100 A45 45 0 0 1 100 55 z"/>',
                '<linearGradient x1="50%" y1="0%" x2="50%" y2="100%" id="nnneon-grad">',
                '<stop stop-color="hsl(162, 100%, 58%)" stop-opacity="1" offset="0%"/>',
                '<stop stop-color="hsl(230, 55%, 70%)" stop-opacity="1" offset="100%"/>',
                '</linearGradient>',
                '<filter id="nnneon-filter" x="-100%" y="-100%" width="400%" height="400%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="17 8" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur"/>',
                '</filter>',
                '<filter id="nnneon-filter2" x="-100%" y="-100%" width="100%" height="100%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="10 17" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur"/>',
                '</filter>',
                '</defs>',
                '<g stroke-width="16" stroke="url(#nnneon-grad)" fill="none">',
                '<rect width="700" height="700" x="50" y="50" filter="url(#nnneon-filter)" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="88" y="50" filter="url(#nnneon-filter2)" opacity="0.25" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="12" y="50" filter="url(#nnneon-filter2)" opacity="0.25" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="50" y="50" rx="45" ry="45"/>',
                '</g>',
                '<g>',
                '<text y="200" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="60px">',
                params.merchantName,
                '</text>',
                '<text y="260" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="35px">',
                params.planName,
                '</text>',
                '<text y="450" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Billing Period : ', params.planPeriod,
                '</text>',
                '<text y="480" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Payment Token : ', params.paymentTokenName,
                '</text>',
                '<text y="510" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Price Per Billing Period : ', params.price, ' (', params.paymentTokenSymbol, ')',
                '</text>',
                '<text y="540" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Payee Address : ', params.payeeAddress,
                '</text>',
                '<text y="570" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Enabled : ', "TRUE",
                '</text>',
                '<text y="600" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Is SBT : ', "FALSE",
                '</text>',
                '<text y="630" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Subscription Start Time : ', params.startDateTime,
                '</text>',
                '<text y="660" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Subscription End Time : ', params.endDateTime,
                '</text>',
                '<text y="690" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Next Bill Time : ', params.nextBillDateTime,
                '</text>',
                '</g>',
                '<g>',
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 1920 1920" preserveAspectRatio="xMidYMid meet" x="600" y="630">',
                '<g transform="translate(0.000000,1920.000000) scale(0.100000,-0.100000)" fill="white" stroke="none">',
                '<path d="M8833 13027 c-1855 -1855 -3373 -3379 -3373 -3386 0 -13 1393 -1411 ',
                '1407 -1411 4 0 1210 1202 2680 2672 l2672 2672 27 -24 c73 -68 3899 -3902 ',
                '3902 -3910 2 -5 -753 -766 -1677 -1690 -925 -925 -1681 -1687 -1681 -1693 0 ',
                '-22 1383 -1397 1405 -1397 13 0 823 803 2404 2384 1905 1905 2382 2387 2377 ',
                '2402 -9 27 -6738 6754 -6756 6754 -8 0 -1533 -1518 -3387 -3373z"/>',
                '<path d="M3492 13007 c-1854 -1854 -3372 -3376 -3372 -3381 0 -5 1521 -1530 ',
                '3380 -3389 l3381 -3381 3379 3379 c1859 1859 3380 3385 3380 3390 0 13 -1392 ',
                '1405 -1405 1405 -6 0 -1209 -1199 -2675 -2665 -1466 -1466 -2672 -2665 -2680 ',
                '-2665 -16 0 -3930 3909 -3930 3925 0 6 1199 1209 2665 2675 1466 1466 2665 ',
                '2672 2665 2680 0 20 -1380 1400 -1400 1400 -8 0 -1533 -1518 -3388 -3373z"/>',
                '<path d="M11517 4992 c-383 -383 -697 -702 -697 -707 0 -6 315 -325 699 -709 ',
                '643 -643 701 -698 718 -685 53 42 1383 1381 1383 1393 0 12 -1378 1397 -1397 ',
                '1403 -4 2 -322 -311 -706 -695z"/>',
                '</g>',
                '</svg>',
                '<text text-rendering="optimizeSpeed">',
                '<textPath startOffset="-100%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="0%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="50%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="-50%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '</text>',
                '</g>',
                '</svg>'
            )
        );

        string memory image = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(meta))
            )
        );

        return image;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import {BokkyPooBahsDateTimeLibrary as TimeLib} from "./BokkyPooBahsDateTimeLibrary.sol";

library Period {
    enum PeriodType {
        DAY,
        WEEK,
        MONTH,
        QUARTER,
        YEAR
    }

    function getPeriodName(PeriodType periodType)
        internal
        pure
        returns (string memory name)
    {
        if (periodType == PeriodType.DAY) {
            name = "DAY";
        } else if (periodType == PeriodType.WEEK) {
            name = "WEEK";
        } else if (periodType == PeriodType.MONTH) {
            name = "MONTH";
        } else if (periodType == PeriodType.QUARTER) {
            name = "QUARTER";
        } else if (periodType == PeriodType.YEAR) {
            name = "YEAR";
        }
    }

    function getPeriodTimestamp(PeriodType period, uint256 curTimestamp)
        internal
        pure
        returns (uint ts)
    {
        if (period == PeriodType.DAY) {
            ts = TimeLib.addDays(curTimestamp, 1);
        } else if (period == PeriodType.WEEK) {
            ts = TimeLib.addYears(curTimestamp, 1);
        } else if (period == PeriodType.MONTH) {
            ts = TimeLib.addMonths(curTimestamp, 1);
        } else if (period == PeriodType.QUARTER) {
            ts = TimeLib.addMonths(curTimestamp, 3);
        } else if (period == PeriodType.YEAR) {
            ts = TimeLib.addYears(curTimestamp, 1);
        }
    }

    function getPeriodTimestamp(
        PeriodType period,
        uint count,
        uint256 curTimestamp
    ) internal pure returns (uint ts) {
        if (period == PeriodType.DAY) {
            ts = TimeLib.addDays(curTimestamp, count);
        } else if (period == PeriodType.WEEK) {
            ts = TimeLib.addYears(curTimestamp, count);
        } else if (period == PeriodType.MONTH) {
            ts = TimeLib.addMonths(curTimestamp, count);
        } else if (period == PeriodType.QUARTER) {
            ts = TimeLib.addMonths(curTimestamp, 3 * count);
        } else if (period == PeriodType.YEAR) {
            ts = TimeLib.addYears(curTimestamp, count);
        }
    }

    function convertTimestampToDateTimeString(uint256 timestamp)
        internal
        pure
        returns (string memory)
    {
        (
            uint256 YY,
            uint256 MM,
            uint256 DD,
            uint256 hh,
            uint256 mm,
            uint256 ss
        ) = TimeLib.timestampToDateTime(timestamp);

        string memory year = Strings.toString(YY);
        string memory month;
        string memory day;
        string memory hour;
        string memory minute;
        string memory second;
        if (MM == 0) {
            month = "00";
        } else if (MM < 10) {
            month = string(abi.encodePacked("0", Strings.toString(MM)));
        } else {
            month = Strings.toString(MM);
        }
        if (DD == 0) {
            day = "00";
        } else if (DD < 10) {
            day = string(abi.encodePacked("0", Strings.toString(DD)));
        } else {
            day = Strings.toString(DD);
        }

        if (hh == 0) {
            hour = "00";
        } else if (hh < 10) {
            hour = string(abi.encodePacked("0", Strings.toString(hh)));
        } else {
            hour = Strings.toString(hh);
        }

        if (mm == 0) {
            minute = "00";
        } else if (mm < 10) {
            minute = string(abi.encodePacked("0", Strings.toString(mm)));
        } else {
            minute = Strings.toString(mm);
        }

        if (ss == 0) {
            second = "00";
        } else if (ss < 10) {
            second = string(abi.encodePacked("0", Strings.toString(ss)));
        } else {
            second = Strings.toString(ss);
        }
        return
            string(
                abi.encodePacked(
                    year,
                    "-",
                    month,
                    "-",
                    day,
                    " ",
                    hour,
                    ":",
                    minute,
                    ":",
                    second
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DecimalToString {

    function decimalString(uint256 number, uint8 decimals, bool isPercent) external pure returns(string memory){
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if(tenPowDecimals > number){
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    // With modifications, the below taken
    // from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L189-L231

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = '.';
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ISubTokenDescriptor {
    function tokenURI(address merchantToken, address planManager, address subInfoManager, uint256 subTokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        uint256 year;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        uint256 year;
        uint256 month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _years)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _months)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _hours)
    {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _minutes)
    {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _seconds)
    {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}