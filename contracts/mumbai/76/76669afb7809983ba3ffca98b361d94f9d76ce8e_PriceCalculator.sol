/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PriceCalculator {
    struct Case {
        uint256 asker;
        uint256 bidder;
        uint256 operators;
    }

    mapping (bytes32 => Case) private cases;

    constructor() {
        // Inizializza i casi di negoziazione con i pesi degli operatori
        // per ciascun caso.
        cases[keccak256("lowAttractor")] = Case(25, 25, 50);
        cases[keccak256("highAttractor")] = Case(25, 25, 50);
        cases[keccak256("centralAttractor")] = Case(10, 10, 80);
        cases[keccak256("lowConcentration")] = Case(25, 25, 50);
        cases[keccak256("highConcentration")] = Case(25, 25, 50);
        cases[keccak256("equilibrium")] = Case(30, 30, 40);
    }

    function priceRegions(uint256 a, uint256 b) public pure returns (uint256[5] memory) {
        uint256 m = (a + b) / 2;
        uint256 lm = (a + m) / 2;
        uint256 um = (m + b) / 2;
        return [a, lm, m, um, b];
    }

    function lowAttractor(uint256[] memory operators, uint256[5] memory priceRegions) internal view returns (bool) {
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] > priceRegions[1]) {
                return false;
            }
        }
        return true;
    }

    function highAttractor(uint256[] memory operators, uint256[5] memory priceRegions) internal view returns (bool) {
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] < priceRegions[3]) {
                return false;
            }
        }
        return true;
    }

    function centralAttractor(uint256[] memory operators, uint256[5] memory priceRegions) internal view returns (bool) {
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] <= priceRegions[1] || operators[i] >= priceRegions[3]) {
                return false;
            }
        }
        return true;
    }

    function lowConcentration(uint256[] memory operators, uint256[5] memory priceRegions) internal view returns (bool) {
        uint256 n = 0;
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] < priceRegions[3]) {
                n++;
            }
        }
        uint256 threshold = (operators.length / 3) * 2;
        if (n > threshold) {
            return true;
        } else {
            return false;
        }
    }

    function highConcentration(uint256[] memory operators, uint256[5] memory priceRegions) internal view returns (bool) {
        uint256 n = 0;
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] > priceRegions[1]) {
                n++;
            }
        }
        uint256 threshold = (operators.length / 3) * 2;
        if (n > threshold) {
            return true;
        } else {
            return false;
        }
    }
}