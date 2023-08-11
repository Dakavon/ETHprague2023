
/**
 * This file contains the relevant test cases for the related collect module
 * 
 * Implementation is not needed until LensV2 is published, 
 * because the test environment is different there
 * 
 * Description follows the function names in
 * https://github.com/lens-protocol/core/blob/v2/test/modules/act/collect/BaseFeeCollectModule.t.sol
 * 
 * 
 * 
 * -------------------------
 * Initialization test cases
 * -------------------------
 * 
 * From BaseFeeCollectModule (see link above):
 * ------------------------------------------
 * 
 * testCannotInitializeWithNonWhitelistedCurrency
 * testCannotInitializeWithReferralFeeGreaterThanMaxBPS
 * testCannotInitializeWithPastNonzeroTimestamp
 * testCannotInitializeIfCalledFromNonActionModuleAddress
 * testCannotInitializeWithWrongInitDataFormat
 * 
 * testInitializeWithCorrectInitData
 * 
 * 
 * Specific for V3PartialCarbonRetirementCollectModule:
 * ---------------------------------------------------
 * 
 * testCannotInitializeWithNonWhitelistedPoolToken
 * testCannotInitializeIfNoSwapPathFromCurrencyToPoolTokenExists
 * testCannotInitializeWithRetirementSplitGreaterThanMaxBPS
 * 
 * 
 * -------------------------
 * Collection test cases
 * -------------------------
 * 
 * From BaseFeeCollectModule (see link above):
 * ------------------------------------------
 * 
 * testCannotProcessCollect_IfCalledFrom_NonActionModuleAddress
 * testCannotProcessCollect_PassingWrongAmountInData
 * testCannotProcessCollect_PassingWrongCurrencyInData
 * testCannotCollectIfNotAFollower
 * testCannotProcessCollect_AfterEndTimestamp
 * testCannotCollectMoreThanLimit
 * 
 * testCanCollectIfAllConditionsAreMet
 * testCurrentCollectsIncreaseProperlyWhenCollecting
 * 
 * Specific for V3PartialCarbonRetirementCollectModule:
 * ---------------------------------------------------
 * 
 * testCannotProcessCollect_PassingWrongPoolTokenInData
 * testCannotProcessCollect_PassingWrongRetirementSplitInData
 * 
 * testCanCollectWithoutRetirementIfNoSwapPathFromCurrencyToPoolTokenExists
 * testCanCollectWithRecipientAmountIsFullAmountIfNoSwapPathFromCurrencyToPoolTokenExists
 * 
 * 
 * -------------------------
 * Fee distribution
 * -------------------------
 * 
 * From BaseFeeCollectModule (see link above):
 * ------------------------------------------
 * 
 * testVerifyFeesSplit
 * 
 * 
 * 
 * 
 * 
*/
