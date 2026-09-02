# X Developer Account - Use Case Description

Copy and paste the following text into the "Describe all of your use cases of X's data and API" field.

***

**1. Core Use Case: Community Verification**
We are developing "Catcoin PoE", a community companion app for our project. The primary use of the X API is to verify that our app users are active members of our X community.
*   **How it works:** Users enter their X handle in our app to claim "Community Benefits".
*   **API Usage:** We use the `GET /2/users/by/username/:username` endpoint to verify the handle exists and resolve its ID. We then use the `GET /2/users/:id/following` endpoint to check if that user is following our official community account (@your_official_x_handle).
*   **Goal:** To confirm membership and unlock specific features within our app for verified community members.

**2. Content Display & Engagement**
We post important updates, events, and missions on our official X account and want to ensure our community sees them.
*   **API Usage:** We plan to use the `GET /2/users/:id/tweets` (User Tweet Timeline) endpoint to fetch and display the latest posts from our official account directly in the app.
*   **Goal:** To surface our latest promotional content to app users, ensuring they are aware of new initiatives.

**3. Verified Sharing (Retweet Check)**
To foster a highly active community, we also want to verify if users have shared our critical community updates.
*   **API Usage:** We plan to use the `GET /2/tweets/:id/retweeted_by` endpoint to check if a specific community announcement has been shared by the user.
*   **Goal:** To acknowledge and validate the efforts of community members who help spread awareness of our project updates.

**4. No Automated Actions**
Our application is **strictly read-only**. We do **not** post tweets, like, retweet, or follow other users on behalf of our users. We do not write any data to the X platform.

**5. Data Analysis & Privacy**
*   We do **not** analyze User data for profiling, surveillance, or advertising.
*   We only check for the existence of specific interactions (Following, Retweeting) related to our official account.
*   We do not store or share this data with third parties.
