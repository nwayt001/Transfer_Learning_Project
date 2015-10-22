using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net.Sockets;
using System.Net.NetworkInformation;
using System.Net.Configuration;
using System.Net;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Controls;

namespace RSVP_Feedback_WPF
{
    
    class BCI2000comm
    {
        #region Fields

        // UDP communication fields
        //Receive
        private const int listenPort = 20321;
        UdpClient receiver;
        Socket receive_socket;
        IPAddress receive_from_address;
        IPEndPoint receive_end_point;
        UdpState s;
        byte[] receive_buffer;

        public bool udpRunning = false;

        // UDP object State for Async callback
        struct UdpState
        {
            public IPEndPoint e;
            public UdpClient u;
        }

        MainWindow mainWindow;

        #endregion Fields

        // Constructor
        public BCI2000comm(MainWindow mainWindow)
        {
            this.mainWindow = mainWindow;
            Console.WriteLine("Communication to BCI2000 initiated...");
        }

        //Threaded version of BCI 2000 reciever - V2
        // This is now modified for label refining 
        public void BCIthrededCommLabelRefine()
        {
            // set up udp socket to receive feedback from the RSVP matlabfilter 
            receive_socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
            receive_from_address = IPAddress.Parse("127.0.0.1");
            receive_end_point = new IPEndPoint(receive_from_address, 1235);
            receiver = new UdpClient(receive_end_point);

            while (udpRunning)
            {
                TopFeedBackImages topFeedbackimages = new TopFeedBackImages();
                topFeedbackimages.targetImages = new int[10];
                topFeedbackimages.nonTargetImages = new int[10];

                //blocking call - receive feedback from bci2000
                receive_buffer = receiver.Receive(ref receive_end_point);

                //decode feedback
                char[] c = Encoding.ASCII.GetChars(receive_buffer);

                bool isTarget = true;
                bool isEmpty = true;
                int cnt = 0;
                List<char> imageChar = new List<char>();

                for (int i = 0; i < c.Length; i++)
                {
                    if (c[i] == 'T')
                    {
                        isTarget = true;
                        cnt = 0;
                    }
                    else if(c[i] == 'N')
                    {
                        isTarget = false;
                        cnt = 0;
                    }
                    else if (c[i] == ' ')
                    {
                        if (!isEmpty)
                        {
                            if (isTarget == true)
                                topFeedbackimages.targetImages[cnt] = int.Parse(new string(imageChar.ToArray()), System.Globalization.CultureInfo.InvariantCulture.NumberFormat);
                            else
                                topFeedbackimages.nonTargetImages[cnt] = int.Parse(new string(imageChar.ToArray()), System.Globalization.CultureInfo.InvariantCulture.NumberFormat);
                            cnt++;
                        }
                        isEmpty = true;
                        imageChar = new List<char>();

                    }
                    else
                    {
                        imageChar.Add(c[i]);
                        isEmpty = false;
                    }
                }
                // Update screen
                mainWindow.mUiContext.Post(mainWindow.UpdateImageLabelRefine, topFeedbackimages);
            }
        }

        //Threaded version of BCI 2000 receiver
        public void BCIthreadedComm()
        {
            // set up udp socket to receive feedback from the RSVP matlabfilter 
            receive_socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
            receive_from_address = IPAddress.Parse("127.0.0.1");
            receive_end_point = new IPEndPoint(receive_from_address, 1235);
            receiver = new UdpClient(receive_end_point);

            // keep checking for udp input
            while (udpRunning)
            {
                //blocking call - receive feedback from bci2000
                receive_buffer = receiver.Receive(ref receive_end_point);

                //decode feedback
                char[] c = Encoding.ASCII.GetChars(receive_buffer);
                char[] imTmp = c.Skip(1).ToArray();
                int idx=0;
                for (int i = 0; i < imTmp.Length; i++)
                {
                    if (imTmp[i] == 'S')
                        idx = i;
                }
                char[] im = new char[idx];
                for (int i = 0; i < im.Length; i++)
                {
                    im[i] = imTmp[i];
                }
                string imStr = new string(im);
                char[] s = imTmp.Skip(idx+1).ToArray();
                string scoreStr = new string(s);

                //Build Image feedback structure
                ImageFeedback imageFeedback = new ImageFeedback();
                imageFeedback.score = float.Parse(scoreStr, System.Globalization.CultureInfo.InvariantCulture.NumberFormat);
                imageFeedback.imNumber = int.Parse(imStr, System.Globalization.CultureInfo.InvariantCulture.NumberFormat);
                imageFeedback.imName = imStr;

                //Decode groundtruth target non/target
                if (imageFeedback.imNumber < 217)
                    imageFeedback.isTarget = false;
                else
                    imageFeedback.isTarget = true;

                // Decode target/nontarget prediction
                if (c[0] == 'T')
                {
                    imageFeedback.isPredictedTarget = true;
                    imageFeedback.score = imageFeedback.score * -1.0;
                    mainWindow.mUiContext.Post(mainWindow.UpdateImage, imageFeedback);
                }
                else if (c[0] == 'N')
                {
                    imageFeedback.isPredictedTarget = false;
                    mainWindow.mUiContext.Post(mainWindow.UpdateImage, imageFeedback);
                }
                else
                {
                    imageFeedback.displayAccuracy = true;
                    imageFeedback.balAcc = imageFeedback.score;
                    mainWindow.mUiContext.Post(mainWindow.UpdateAccuracy, imageFeedback);
                }
                
            }
                
        }

        //Initialize UDP communication
        public void InitAsyncComms()
        {
            //Initialize UDP communications
            //Receive
            receive_socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
            receive_from_address = IPAddress.Parse("127.0.0.1");
            //receive_end_point = new IPEndPoint(receive_from_address, 20321);
            receive_end_point = new IPEndPoint(receive_from_address, 1235);
            receiver = new UdpClient(receive_end_point);

            s = new UdpState();
            s.e = receive_end_point;
            s.u = receiver;

            //register async callback for UDP communication
            receiver.BeginReceive(new AsyncCallback(ParseBCIdata), s);
        }

        ///<summary>
        // Parse BCI data and translate into application commands
        ///</summary>
        void ParseBCIdata(IAsyncResult BciData)
        {
            //Parse out the client info from the state object
            UdpClient u = (UdpClient)((UdpState)(BciData.AsyncState)).u;
            IPEndPoint e = (IPEndPoint)((UdpState)(BciData.AsyncState)).e;
            try
            {
                //get the actual data
                receive_buffer = u.EndReceive(BciData, ref receive_end_point);
                //OutputClass = BitConverter.ToInt16(receive_buffer, 0);

                char[] c = Encoding.ASCII.GetChars(receive_buffer);
                //Device Control
                //sendCommand(OutputClass);
                Console.Write("Received: ");
                char[] im = c.Skip(1).ToArray();
                
                Console.WriteLine(im);
                
                // Decode target/nontarget
                if (c[0] == 'T')
                {
                    Console.WriteLine("This is a Target!");
                }
                else
                {
                    Console.WriteLine("This is a Non-Target!");
                }

                //display corresponding image
                try
                {
                    mainWindow.UpdateImage(im);
                   // DisplayImage(im);
                }
                catch(Exception exx) {Console.WriteLine(exx.ToString()); }

                //register the async callback again
                receiver.BeginReceive(new AsyncCallback(ParseBCIdata), s);
            }
            catch (Exception) { }
        }
    }
}
