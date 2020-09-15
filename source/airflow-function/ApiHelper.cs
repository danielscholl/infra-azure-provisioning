using Microsoft.Extensions.Logging;
using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using ILogger = Microsoft.Extensions.Logging.ILogger;

namespace MyFunctionProj
{
    class ApiHelper
    {
        // You can use an optional field to specify the timestamp from the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
        static string TimeStampField = "";

        /// <summary>
        /// Send Logs into Azure Log Workspace
        /// </summary>
        /// <param name="json"></param>
        /// <param name="customerId">customerId to your Log Analytics workspace ID</param>
        /// <param name="sharedKey">For sharedKey, use either the primary or the secondary Connected Sources client authentication key   </param>
        /// <param name="logName">LogName is name of the event type that is being submitted to Azure Monitor</param>
        /// <param name="log"></param>
        public static void SendLogs(string json, string customerId, string sharedKey, string logName, ILogger log)
        {
            // Create a hash for the API signature
            var datestring = DateTime.UtcNow.ToString("r");
            var jsonBytes = Encoding.UTF8.GetBytes(json);
            string stringToHash = "POST\n" + jsonBytes.Length + "\napplication/json\n" + "x-ms-date:" + datestring + "\n/api/logs";
            string hashedString = BuildSignature(stringToHash, sharedKey);
            string signature = "SharedKey " + customerId + ":" + hashedString;

            PostData(signature, datestring, json, customerId, logName, log);
        }

        // Build the API signature
        protected static string BuildSignature(string message, string secret)
        {
            var encoding = new System.Text.ASCIIEncoding();
            byte[] keyByte = Convert.FromBase64String(secret);
            byte[] messageBytes = encoding.GetBytes(message);
            using (var hmacsha256 = new HMACSHA256(keyByte))
            {
                byte[] hash = hmacsha256.ComputeHash(messageBytes);
                return Convert.ToBase64String(hash);
            }
        }

        /// <summary>
        /// Send a request to the POST API endpoint
        /// </summary>
        /// <param name="signature"></param>
        /// <param name="date"></param>
        /// <param name="json"></param>
        /// <param name="customerId"></param>
        /// <param name="LogName"></param>
        /// <param name="log"></param>
        protected static void PostData(string signature, string date, string json, string customerId, string LogName, ILogger log)
        {
            try
            {
                string url = "https://" + customerId + ".ods.opinsights.azure.com/api/logs?api-version=2016-04-01";

                System.Net.Http.HttpClient client = new System.Net.Http.HttpClient();
                client.DefaultRequestHeaders.Add("Accept", "application/json");
                client.DefaultRequestHeaders.Add("Log-Type", LogName);
                client.DefaultRequestHeaders.Add("Authorization", signature);
                client.DefaultRequestHeaders.Add("x-ms-date", date);
                client.DefaultRequestHeaders.Add("time-generated-field", TimeStampField);

                System.Net.Http.HttpContent httpContent = new StringContent(json, Encoding.UTF8);
                httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/json");
                Task<System.Net.Http.HttpResponseMessage> response = client.PostAsync(new Uri(url), httpContent);

                System.Net.Http.HttpContent responseContent = response.Result.Content;
                string result = responseContent.ReadAsStringAsync().Status.ToString();
                log.LogInformation("Return Result: " + result);
            }
            catch (Exception excep)
            {
                log.LogError($"API Post Exception: {excep.Message}");
            }
        }
    }
}