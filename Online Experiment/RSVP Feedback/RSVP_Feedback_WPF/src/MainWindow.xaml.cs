using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Threading;


namespace RSVP_Feedback_WPF
{
    public struct ImageFeedback
    {
        public string imName;
        public int imNumber;
        public double score;
        public bool isTarget;
        public bool isPredictedTarget;
        public bool displayAccuracy;
        public double balAcc;
    }

    public struct TopFeedBackImages
    {
        public int[] targetImages;
        public int[] nonTargetImages;
    }
    
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        #region Fields
        //Fields
        int imageWIDTH = 300;
        int imageHEIGHT = 205;
        System.Windows.Thickness imageTHICKNESS = new Thickness(5);
        BCI2000comm bciComm;
        public System.Windows.Forms.WindowsFormsSynchronizationContext mUiContext = new System.Windows.Forms.WindowsFormsSynchronizationContext();
        const int numImages = 10;
        Image[] CurrentTargetImages = new Image[11];
        Image[] CurrentNonTargetImages = new Image[11];
        double[] CurrentTargetScores = new double[11];
        double[] CurrentNonTargetScores = new double[11];
        ImageFeedback imageFeedback;
        TopFeedBackImages topFeedBackImages;
        string ImagesDirectory =
        System.IO.Path.Combine(
        System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location),
        "images"
        );
        #endregion Fields
        
        //Constructor
        public MainWindow()
        {
            InitializeComponent();
            // Initialize the individual components in code
            InitScreen();
            
            //Initiate threaded communication
            bciComm = new BCI2000comm(this);

            //BCI communication thread
            Thread bciThread = new Thread(bciComm.BCIthreadedComm);
            //Thread bciThread = new Thread(bciComm.BCIthrededCommLabelRefine);
            bciThread.SetApartmentState(ApartmentState.STA);
            bciComm.udpRunning = true;
            bciThread.Start();            
        }

        //close thread
        protected override void OnClosed(EventArgs e)
        {
            bciComm.udpRunning = false;
            base.OnClosed(e);
        }

        //Update accuracy feedback
        public void UpdateAccuracy(object userData)
        {
            imageFeedback = (ImageFeedback)userData;
            
            float tmpAcc = (float)imageFeedback.balAcc * 100;
            string acc = Convert.ToString(tmpAcc);
            char[] accChar = new char[5];
            for (int i = 0; i < accChar.Length; i++)
            {
                accChar[i] = acc[i];
            }

            label1.Content = string.Concat("Accuracy (Pi) = ", new string(accChar)," %");

            Console.WriteLine(new string(accChar));
        }

        //Update images using the label refine feature
        public void UpdateImageLabelRefine(object userData)
        {
            topFeedBackImages = (TopFeedBackImages)userData;


            // update target images
            stackPanel1.Children.RemoveRange(0, stackPanel1.Children.Count);
            stackPanel2.Children.RemoveRange(0, stackPanel2.Children.Count);

            for (int i = 0; i < 10; i++)
            {
                //target images
                string imName = string.Concat(topFeedBackImages.targetImages[i].ToString(), ".bmp");
                BitmapImage bitImg = new BitmapImage(new Uri(System.IO.Path.Combine(ImagesDirectory,imName), UriKind.Absolute));
                Image img = new Image();
                img.Source = bitImg;
                img.Width = 300;
                img.Height = 205;
                System.Windows.Thickness th = new System.Windows.Thickness(5);
                img.Margin = th;
                if (i < 5)
                    stackPanel1.Children.Add(img);
                else
                    stackPanel2.Children.Add(img);
            }

            // update nontarget images
            stackPanel3.Children.RemoveRange(0, stackPanel3.Children.Count);
            stackPanel4.Children.RemoveRange(0, stackPanel4.Children.Count);
            for (int i=0;i<10;i++)
            {
                //non-target images
                string imName = string.Concat(topFeedBackImages.nonTargetImages[i].ToString(), ".bmp");
                BitmapImage bitImg = new BitmapImage(new Uri(System.IO.Path.Combine(ImagesDirectory, imName), UriKind.Absolute));
                Image img = new Image();
                img.Source = bitImg;
                img.Width = 300;
                img.Height = 205;
                System.Windows.Thickness th = new System.Windows.Thickness(5);
                img.Margin = th;
                if (i < 5)
                    stackPanel3.Children.Add(img);
                else
                    stackPanel4.Children.Add(img);
            }
        }

        //Update images
        public void UpdateImage(object userData)
        {
            imageFeedback = (ImageFeedback)userData;
            string imName = imageFeedback.imName;
            imName = string.Concat(imName,".bmp");
            string dir = System.IO.Path.Combine(ImagesDirectory, imName);
            BitmapImage bitImg = new BitmapImage(new Uri(dir, UriKind.Absolute));
            Image img = new Image();
            img.Source = bitImg;
            img.Width = 300;
            img.Height = 205;
            System.Windows.Thickness th = new System.Windows.Thickness(5);
            img.Margin = th;

            // Determine where to put image based on groundTruth, score and display
            if (imageFeedback.isPredictedTarget)
            {
                // Update Target Images
                CurrentTargetScores[CurrentTargetScores.Length - 1] = imageFeedback.score;
                CurrentTargetImages[CurrentTargetImages.Length - 1] = img;
                // Resort
                 Array.Sort(CurrentTargetScores, CurrentTargetImages);
                // Update
                 stackPanel1.Children.RemoveRange(0, stackPanel1.Children.Count);
                 stackPanel2.Children.RemoveRange(0, stackPanel2.Children.Count);
                 for (int j = 0; j < CurrentTargetScores.Length-1; j++)
                 {
                     if (j < 5)
                         stackPanel1.Children.Add(CurrentTargetImages[j]);
                     else
                         stackPanel2.Children.Add(CurrentTargetImages[j]);
                 }
            }
            else
            {
                // Update Non Target Images
                CurrentNonTargetScores[CurrentNonTargetScores.Length - 1] = imageFeedback.score;
                CurrentNonTargetImages[CurrentNonTargetImages.Length - 1] = img;
                // Resort
                Array.Sort(CurrentNonTargetScores, CurrentNonTargetImages);
                // Update
                stackPanel3.Children.RemoveRange(0, stackPanel3.Children.Count);
                stackPanel4.Children.RemoveRange(0, stackPanel4.Children.Count);
                for (int j = 0; j < CurrentTargetScores.Length-1; j++)
                {
                    if (j < 5)
                        stackPanel3.Children.Add(CurrentNonTargetImages[j]);
                    else
                        stackPanel4.Children.Add(CurrentNonTargetImages[j]);
                }
            }
        }

        //Init Screen Layout
        public void InitScreen()
        {
            
            string dir = System.IO.Path.Combine(ImagesDirectory, "noPhoto.png");
            BitmapImage bitImg = new BitmapImage(new Uri(dir, UriKind.Absolute));

            // Add 10 target images
            for (int i = 0; i < numImages+1; i++)
            {
                bitImg = new BitmapImage(new Uri(dir, UriKind.Absolute));
                CurrentTargetImages[i] = new Image();
                CurrentTargetImages[i].Source = bitImg;
                CurrentTargetImages[i].Width = imageWIDTH;
                CurrentTargetImages[i].Height = imageHEIGHT;
                CurrentTargetImages[i].Margin = imageTHICKNESS;
                if (i < 10)
                {
                    if (i < 5)
                        stackPanel1.Children.Add(CurrentTargetImages[i]);
                    else
                        stackPanel2.Children.Add(CurrentTargetImages[i]);
                }
                CurrentTargetScores[i] = 2.0f;
            }

            // Add 10 non-target images
            for (int i = 0; i < numImages+1; i++)
            {
                bitImg = new BitmapImage(new Uri(dir, UriKind.Absolute));
                CurrentNonTargetImages[i] = new Image();
                CurrentNonTargetImages[i].Source = bitImg;
                CurrentNonTargetImages[i].Width = imageWIDTH;
                CurrentNonTargetImages[i].Height = imageHEIGHT;
                CurrentNonTargetImages[i].Margin = imageTHICKNESS;
                if (i < 10)
                {
                    if (i < 5)
                        stackPanel3.Children.Add(CurrentNonTargetImages[i]);
                    else
                        stackPanel4.Children.Add(CurrentNonTargetImages[i]);
                }
                CurrentNonTargetScores[i] = 2.0f;
            }
        }
    }
}
