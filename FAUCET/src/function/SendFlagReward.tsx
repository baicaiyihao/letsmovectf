import React, { useState } from "react";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { networkConfig } from "../config/networkConfig";

const SendFlagReward: React.FC<{ onSuccess: () => void }> = ({ onSuccess }) => {
    const currentAccount = useCurrentAccount();
    const { mutateAsync: signAndExecute, isError, error } = useSignAndExecuteTransaction();
    const PackageChallenge = networkConfig.testnet.packageChallenge;
    const AdminCap = networkConfig.testnet.adminCap;
    const FlagPool = networkConfig.testnet.flag_pool;
    const UserList = networkConfig.testnet.UserList;
    const Challenge = networkConfig.testnet.ChallengeTable;

    const [loading, setLoading] = useState(false);
    const [userAddress, setUserAddress] = useState('');
    const [challengeId, setChallengeId] = useState('0001');
    const [errorMessage, setErrorMessage] = useState('');

    const create = async () => {
        if (!currentAccount?.address) {
            console.error("No connected account found.");
            setErrorMessage("No connected account found.");
            return;
        }
        if (!userAddress || !/^0x[a-fA-F0-9]{64}$/.test(userAddress)) {
            console.error("Invalid user address format.");
            setErrorMessage("Invalid user address format.");
            return;
        }
        console.log("Address", currentAccount.address);
        setLoading(true);
        try {
            const tx = new Transaction();
            tx.setGasBudget(10000000);

            tx.moveCall({
                package: PackageChallenge,
                module: "challenge",
                function: "send_flag_reward",
                typeArguments:[networkConfig.testnet.PLEDGEX_FAUCET],
                arguments: [
                    tx.object(AdminCap),
                    tx.object(FlagPool),
                    tx.pure.option('address',userAddress),
                    tx.pure.address(userAddress),
                    tx.object(UserList),
                    tx.object(Challenge),
                    tx.pure.string(challengeId),
                ],
            });
            const result = await signAndExecute({ transaction: tx });
            if (result && !isError) {
                onSuccess();
                setErrorMessage('');
            }
        } catch (err) {
            console.error(err);
            setErrorMessage("An error occurred while sending the reward flag.");
        } finally {
            setLoading(false);
        }
    };

    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', maxWidth: '300px' }}>
          <input
            type="text"
            placeholder="Enter user address"
            value={userAddress}
            onChange={(e) => setUserAddress(e.target.value)}
            disabled={loading}
            style={{ padding: '8px', fontSize: '14px' }}
          />
          <input
            type="text"
            placeholder="Enter challenge ID"
            value={challengeId}
            onChange={(e) => setChallengeId(e.target.value)}
            disabled={loading}
            style={{ padding: '8px', fontSize: '14px' }}
          />
          {errorMessage && <p style={{ color: 'red', fontSize: '12px' }}>{errorMessage}</p>}
          <button
            onClick={create}
            disabled={loading || !userAddress || !challengeId}
            style={{
                padding: '10px',
                fontSize: '14px',
                backgroundColor: '#007bff',
                color: '#fff',
                border: 'none',
                borderRadius: '5px',
                cursor: loading ? 'not-allowed' : 'pointer',
                opacity: loading ? 0.7 : 1,
            }}
          >
              {loading ? 'Loading...' : 'Send Reward Flag'}
          </button>
      </div>
    );
};

export default SendFlagReward;



