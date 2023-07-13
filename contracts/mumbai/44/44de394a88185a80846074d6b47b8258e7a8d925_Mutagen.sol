// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Mutagen {

    type Classification is uint8;

    enum AgentType { PHYSICAL, CHEMICAL, BIOLOGICAL }

    enum PhysicalClassification { HEAT, RADIATION }

    enum ChemicalClassification { BASE_ANALOGS, INTERCALATING_AGENTS, METAL_IONS, ALKYLATING_AGENTS }

    enum BiologicalClassification { TRANSPOSONS_IS, VIRUS, BACTERIA, OTHER }


    function matchClassification(AgentType agent, Classification classification) external pure returns(bool) {
       if (AgentType.PHYSICAL == agent) {
        return physicalAgentClassification(classification);
       } else if (AgentType.CHEMICAL == agent) {
        return chemicalAgentClassification(classification);
       } else if (AgentType.BIOLOGICAL == agent) {
        return biologicalAgentClassification(classification);
       }
       return false;
    }

    function physicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(PhysicalClassification.HEAT) == _unwrappedClassification) {
            return true;
        } else if (uint8(PhysicalClassification.RADIATION) == _unwrappedClassification) {
            return true;
        } 
        return false;
    }

    function chemicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(ChemicalClassification.BASE_ANALOGS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.INTERCALATING_AGENTS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.METAL_IONS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.ALKYLATING_AGENTS) == _unwrappedClassification) {
            return true;
        } 
        return false;
    }

    function biologicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(BiologicalClassification.TRANSPOSONS_IS) == _unwrappedClassification) {
            return true;
        } else if (uint8(BiologicalClassification.VIRUS) == _unwrappedClassification) {
            return true;
        } else if (uint8(BiologicalClassification.BACTERIA) == _unwrappedClassification) {
            return true;
        }
        return false;
    } 
}