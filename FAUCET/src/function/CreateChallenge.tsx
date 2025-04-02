import React, { useState } from "react";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { networkConfig, suiClient } from "../config/networkConfig";

const CreateChallenge: React.FC<{ onSuccess: () => void }> = ({ onSuccess }) => {
    const currentAccount = useCurrentAccount();
    const { mutateAsync: signAndExecute, error } = useSignAndExecuteTransaction();
    const PackageChallenge = networkConfig.testnet.packageChallenge;
    const AdminCap = networkConfig.testnet.adminCap;
    const ChallengeTable = networkConfig.testnet.ChallengeTable;
    const [loading, setLoading] = useState(false);
    const [challengeId, setChallengeId] = useState("");
    const [contactId, setContactId] = useState("");
    const [category, setCategory] = useState("");
    const [title, setTitle] = useState("");
    const [tips, setTips] = useState("");
    const [rewardCoins, setRewardCoins] = useState(1);
    const [firstBloodReward, setFirstBloodReward] = useState(1);
    const [secondBloodReward, setSecondBloodReward] = useState(1);
    const [thirdBloodReward, setThirdBloodReward] = useState(1);
    const [otherBloodReward, setOtherBloodReward] = useState(1);
    const [description, setDescription] = useState("");
    const [points, setPoints] = useState(0);
    const [errors, setErrors] = useState({});

    const validateForm = () => {
        const newErrors = {};
        if (!challengeId) newErrors.challengeId = "Challenge ID is required.";
        if (!contactId) newErrors.contactId = "Contact ID is required.";
        if (!category) newErrors.category = "Category is required.";
        if (!title) newErrors.title = "Title is required.";
        if (!description) newErrors.description = "Description is required.";
        if (points <= 0) newErrors.points = "Points must be greater than zero.";
        if (rewardCoins <= 0) newErrors.rewardCoins = "Reward coins must be greater than zero.";
        if (firstBloodReward < 0) newErrors.firstBloodReward = "First blood reward cannot be negative.";
        if (secondBloodReward < 0) newErrors.secondBloodReward = "Second blood reward cannot be negative.";
        if (thirdBloodReward < 0) newErrors.thirdBloodReward = "Third blood reward cannot be negative.";
        if (otherBloodReward < 0) newErrors.otherBloodReward = "Other blood reward cannot be negative.";

        return newErrors;
    };


    const create = async () => {
        const state_field = await suiClient.getDynamicFields({
          parentId: "0xf1d1c79e40e606b89c72c0f79bee85edda0fcae80b0b862c4faf1553c6dd32f5",
        }) as any;

        console.log(state_field);

      const state_field1 = await suiClient.getObject({
        id: "0x66c5535d2e2b70ceb471ed1082a44cb2d99f797c7b484f61d1fb974cec84c826",
        options: { showContent: true }
      }) as any;

      console.log(state_field1);
        if (!currentAccount?.address) {
            console.error("No connected account found.");
            setErrors({ general: "No connected account found." });
            return;
        }

        const validationErrors = validateForm();
        if (Object.keys(validationErrors).length > 0) {
            setErrors(validationErrors);
            return;
        }

        setLoading(true);
        try {
            const tx = new Transaction();
            tx.setGasBudget(10000000);

            tx.moveCall({
                package: PackageChallenge,
                module: "challenge",
                function: "AddChallenge",
                arguments: [
                    tx.object(AdminCap),
                    tx.object(ChallengeTable),
                    tx.pure.string(challengeId), // challenge_id
                    tx.pure.address(contactId), // contact_id
                    tx.pure.string(category), // category
                    tx.pure.string(title), // title
                    tx.pure.option('string', tips), // tips
                    tx.pure.string(description), // description
                    tx.pure.u64(BigInt(points)), // points
                    tx.pure.u64(BigInt(rewardCoins)), // reward_coins
                    tx.pure.u64(BigInt(firstBloodReward)), // first_blood_reward
                    tx.pure.u64(BigInt(secondBloodReward)), // second_blood_reward
                    tx.pure.u64(BigInt(thirdBloodReward)), // third_blood_reward
                    tx.pure.u64(BigInt(otherBloodReward)), // other_blood_reward
                    tx.pure.u64(BigInt(0)), // solved_count
                    tx.pure.option('address', null), // first_blood
                    tx.pure.option('address', null), // second_blood
                    tx.pure.option('address', null), // third_blood
                    tx.pure.bool(true), // is_published
                ],
            });

            const result = await signAndExecute({ transaction: tx });
            if (result && !error) {
                onSuccess();
            }
        } catch (err) {
            console.error(err);
            setErrors({ general: "Failed to create challenge. Please check your inputs and try again." });
        } finally {
            setLoading(false);
        }
    };

    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          <div>
              <input
                type="text"
                placeholder="Enter challenge id"
                value={challengeId}
                onChange={(e) => setChallengeId(e.target.value)}
              />
              {errors.challengeId && <span style={{ color: 'red' }}>{errors.challengeId}</span>}
          </div>
          <div>
              <input
                type="text"
                placeholder="Enter contact id"
                value={contactId}
                onChange={(e) => setContactId(e.target.value)}
              />
              {errors.contactId && <span style={{ color: 'red' }}>{errors.contactId}</span>}
          </div>
          <div>
              <input
                type="text"
                placeholder="Enter category"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              />
              {errors.category && <span style={{ color: 'red' }}>{errors.category}</span>}
          </div>
          <div>
              <input
                type="text"
                placeholder="Enter title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
              {errors.title && <span style={{ color: 'red' }}>{errors.title}</span>}
          </div>
          <div>
              <input
                type="text"
                placeholder="Enter tips"
                value={tips}
                onChange={(e) => setTips(e.target.value)}
              />
          </div>
          <div>
                <textarea
                  rows={4}
                  placeholder="Enter description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                />
              {errors.description && <span style={{ color: 'red' }}>{errors.description}</span>}
          </div>
          <div>
              <input
                type="number"
                placeholder="Enter points"
                value={points}
                onChange={(e) => setPoints(Number(e.target.value))}
              />
              {errors.points && <span style={{ color: 'red' }}>{errors.points}</span>}
          </div>
          <div>
              <input
                type="number"
                placeholder="Enter reward coins"
                value={rewardCoins}
                onChange={(e) => setRewardCoins(Number(e.target.value))}
              />
              {errors.rewardCoins && <span style={{ color: 'red' }}>{errors.rewardCoins}</span>}
          </div>
          <div>
              <input
                type="number"
                placeholder="Enter first blood reward"
                value={firstBloodReward}
                onChange={(e) => setFirstBloodReward(Number(e.target.value))}
              />
              {errors.firstBloodReward && <span style={{ color: 'red' }}>{errors.firstBloodReward}</span>}
          </div>
          <div>
              <input
                type="number"
                placeholder="Enter second blood reward"
                value={secondBloodReward}
                onChange={(e) => setSecondBloodReward(Number(e.target.value))}
              />
              {errors.secondBloodReward && <span style={{ color: 'red' }}>{errors.secondBloodReward}</span>}
          </div>
          <div>
              <input
                type="number"
                placeholder="Enter third blood reward"
                value={thirdBloodReward}
                onChange={(e) => setThirdBloodReward(Number(e.target.value))}
              />
              {errors.thirdBloodReward && <span style={{ color: 'red' }}>{errors.thirdBloodReward}</span>}
          </div>
          <div>
              <input
                type="number"
                placeholder="Enter other blood reward"
                value={otherBloodReward}
                onChange={(e) => setOtherBloodReward(Number(e.target.value))}
              />
              {errors.otherBloodReward && <span style={{ color: 'red' }}>{errors.otherBloodReward}</span>}
          </div>
          <button
            onClick={create}
            disabled={loading}
          >
              {loading ? 'Loading...' : 'Add Challenge'}
          </button>
          {errors.general && <p style={{ color: 'red' }}>{errors.general}</p>}
      </div>
    );
};

export default CreateChallenge;



