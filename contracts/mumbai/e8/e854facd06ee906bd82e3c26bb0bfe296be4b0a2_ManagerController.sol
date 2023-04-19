/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract ManagerController  {

    struct VariablesInt {
        string variableNameInt;
        uint valueInt;
    }
    VariablesInt[] variablesInt;
    string[] variableNamesInt;
    uint[] valuesInt;


    struct VariablesDec{
        string variableNameDec;
        uint valueDec;
    }
    VariablesDec[] variablesDec;
    string[] variableNamesDec;
    uint[] valuesDec;

    struct VariablesString{
    string variableNameString;
    string valueString;
    }
    VariablesString[] variablesString;
    string[] variableNamesString;
    string[] valuesString;

    address yousovAccessControl;

    constructor() {
        variableNamesInt = [
            "minimumRecoveryPriceUsd",
            "minimumRecoveryPriceEzr",
            "zeroEZRBalancePriceFactor",
            "numberOfTestsAgentsMo",
            "maximumNumberOfAgents",
            "maxLottery",
            "numberOfAttempsForcing",
            "attempt2Price",
            "attempt3Price",
            "attempt4Price",
            "attempt5Price",
            "minimumAgentsAppear",
            "timeLimitFaucet",
            "bundleOfferExpiration",
            "emptyWalletRecovery",
            "attempt6Delay",
            "attempt7Delay",
            "attempt8Delay",
            "attempt9Delay",
            "attempt10Delay",
            "attempt2Delay",
            "attempt3Delay",
            "attempt4Delay",
            "attempt5Delay"
        ];
        valuesInt = [
            50,
            1,
            2,
            12,
            40000,
            1000000,
            10,
            75,
            100,
            200,
            500,
            500,
            24,
            60,
            2,
            15,
            1,
            24,
            1,
            1,
            1,
            24,
            1,
            1
        ];

        for (uint256 i = 0; i < variableNamesInt.length; i++) {
            variablesInt.push(VariablesInt(variableNamesInt[i], valuesInt[i]));
        }

         variableNamesDec = [
            "testRecoveryRewardRatio",
            "totalAgentsRatio",
            "seniorAgentsRatio",
            "stakingRewardPerYear",
            "seniorAgentRate",
            "juniorAgentRate",
            "standardsRate",
            "deniedRate",
            "agentPayrollWalletFromJunior",
            "agentPayrollWalletFromDenied",
            "agentPayrollWalletFromRecovery",
            "bonusShare",
            "seniorAgentsBonusShare",
            "senioAgentsLotteryOdds",
            "juniorAgentsLotteryOdds",
            "standards",
            "burn",
            "amountFaucet"
            ];
         valuesDec = [
            2500,
            30000,
            150000,
            6000,
            1200000,
            900000,
            750000,
            0,
            800000,
            500000,
            500000,
            800000,
            700000,
            600000,
            150000,
            200000,
            300000,
            100
            ];

         for (uint256 i = 0; i < variableNamesDec.length; i++) {
            variablesDec.push(VariablesDec(variableNamesDec[i], valuesDec[i]));
        }

        variableNamesString = [
            "stakingRewardsPanic",
            "agentRewardsPanic",
            "recoveriesPanic",
            "agentType",
            "urlFaucet"
        ];

        valuesString = [
            "false",
            "false",
            "false",
            "human",
            "http://yousov.com/faucet"
        ];

         for (uint256 i = 0; i < variableNamesString.length; i++) {
            variablesString.push(VariablesString(variableNamesString[i], valuesString[i]));
        }

    }

    function updateVariables(VariablesInt[] memory changedVariables) public {
        for (uint i = 0; i < changedVariables.length; i++) {
            for (uint j = 0; j < variablesInt.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariables[i].variableNameInt)
                    ) == keccak256(abi.encodePacked(variablesInt[j].variableNameInt))
                ) {
                    variablesInt[j].valueInt = changedVariables[i].valueInt;
                }
            }
        }
    }

    function updateVariablesPerc(VariablesDec[] memory changedVariables) public {
        for (uint i = 0; i < changedVariables.length; i++) {
            for (uint j = 0; j < variablesDec.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariables[i].variableNameDec)
                    ) == keccak256(abi.encodePacked(variablesDec[j].variableNameDec))
                ) {
                    variablesDec[j].valueDec = changedVariables[i].valueDec;
                }
            }
        }
    }

    function updateVariablesString(VariablesString[] memory changedVariables) public {
        for (uint i = 0; i < changedVariables.length; i++) {
            for (uint j = 0; j < variablesString.length; j++) {
                if (
                    keccak256(
                        abi.encodePacked(changedVariables[i].variableNameString)
                    ) == keccak256(abi.encodePacked(variablesString[j].variableNameString))
                ) {
                    variablesString[j].valueString = changedVariables[i].valueString;
                }
            }
        }
    }

    function getValueString(
        string memory variableName
    ) public view returns (string memory) {
        string memory vr = "";
        for (uint i = 0; i < variablesString.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesString[i].variableNameString)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesString[i].valueString;
            }
        }
        return vr;
    }

    function getValueInt(
        string memory variableName
    ) public view returns (uint) {
        uint vr;
        for (uint i = 0; i < variablesInt.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesInt[i].variableNameInt)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesInt[i].valueInt;
            }
        }
        return vr;
    }

    function getValueDec(
        string memory variableName
    ) public view returns (uint) {
        uint vr;
        for (uint i = 0; i < variablesDec.length; i++) {
            if (
                keccak256(abi.encodePacked(variablesDec[i].variableNameDec)) ==
                keccak256(abi.encodePacked(variableName))
            ) {
                vr = variablesDec[i].valueDec;
            }
        }
        return vr;
    }

    function getAllValues() public view returns (string memory) {
        string memory resultInt;
        for (uint i = 0; i < variablesInt.length; i++) {
            VariablesInt memory v = variablesInt[i];
            resultInt = string(
                abi.encodePacked(
                    resultInt,
                    "{'name': '",
                    v.variableNameInt,
                    "', 'value': '",
                    uint2str(v.valueInt),
                    "'}, "
                )
            );
        }

        string memory resultDec;
        for (uint i = 0; i < variablesDec.length; i++) {
            VariablesDec memory v = variablesDec[i];
            resultDec = string(
                abi.encodePacked(
                    resultDec,
                    "{'name': '",
                    v.variableNameDec,
                    "', 'value': '",
                    uint2str(v.valueDec),
                    "'}, "
                )
            );
        } 
       
        string memory resultString;
        for (uint i = 0; i < variablesString.length; i++) {
            VariablesString memory v = variablesString[i];
            resultString = string(
                abi.encodePacked(
                    resultString,
                    "{'name': '",
                    v.variableNameString,
                    "', 'value': '",
                    v.valueString,
                    "'}, "
                )
            );
        }

        string memory result;
        //result = string.concat(resultInt, resultDec, resultString);
        result = string(
            abi.encodePacked(
                resultInt,
                resultDec,
                resultString
            )
        );
        return result;
     }

         function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }
}