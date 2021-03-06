import SwiftUI
//Constants
// Swift Playgrounds
var iconSize: CGFloat = 128
var headingSize: CGFloat = 64
var contentSize: CGFloat = 24

var famBoy = Fam()
var spamBoy = Spam()
var model:Classifier = Classifier(newModel: MultinomialTf)

// Common Constants
let factor:CGFloat = 0.75
let flickRatio:CGFloat = 0.25
let appreciation = ["👏🏻 Keep going!", "😄 Great Job", "👌 Good Work"]

let textColor = Color(.sRGB, white: 0, opacity: 0.8)

let spamEmoji:String = "👻"
let famEmoji:String = "👍🏻"

enum SpamFam: Int {
    case spam, fam, none
}

enum Status: Int {
    case start, trainingDone, intervalDone, testingDone
}

public struct ContentView: View {
    @State public var mails: [Mail]
    @State public var testMails: [Mail]
    @State private var mail: Mail = Mail()
    
    @State private var title: String = "📨 Swiftspam"
    @State private var stats: Status = .start
    @State private var testResult: Results = .None
    @State var startTesting = false
    
    @State private var frame: CGSize = .zero // Contains Geometrical dims of current view.
    @State private var cardDim: CGSize = .zero
    @State private var moveCongratsHeight: CGFloat = 0

    func setDims(_ geometry: GeometryProxy) -> some View{
        DispatchQueue.main.async {
            self.frame = geometry.size
            self.cardDim.height = geometry.size.height * factor
            self.cardDim.width = geometry.size.height * factor * 0.6 //Aspect ratio
            // Playgrounds
            if self.cardDim.width <= 400{
                iconSize = 64
                headingSize = 48
                contentSize = 16
            } else {
                // Swift Playgrounds
                iconSize = 128
                headingSize = 64
                contentSize = 24
            }
        }
        return EmptyView()
    }
    
    private var mailsMaxID: Int {
        return self.mails.map { $0.id }.max() ?? 0
    }
    
    private var testMailsMaxID: Int {
        return self.testMails.map { $0.id }.max() ?? 0
    }
    
    private func getCardOffset(mails: [Mail], id: Int) -> CGFloat {
        return  CGFloat(mails.count - 1 - id) * 10
    }
    
    func trainingEmails(_ mx: Mail) -> some View{
        DispatchQueue.main.async{
        if self.mails.count <= 18 {
            self.title = appreciation.randomElement()!
        }

        if self.mails.count <= 10{
            self.title = "\(self.mails.count) mails to go"
        }
        }
        return Group {
            // Range Operator
            if (self.mailsMaxID - 3)...self.mailsMaxID ~= mx.id {
                MailView(size: self.cardDim, mail: mx, mails: self.$mails, dim: self.frame, stats: self.stats, result: self.testResult)
                    .offset(x: 0, y: self.getCardOffset(mails: self.mails, id: mx.id))
                .animation(.spring())
            }
        }
    }

    func interval() -> some View{
        DispatchQueue.main.async{
            if self.mails.count == 0 {
                model = train(fam: famBoy, spam: spamBoy)
                self.title = "💪🏻 Training Done"
                self.stats = .trainingDone
            }
        }
        return EmptyView()
    }
    
    func testEmails(_ mx: Mail) -> some View{
        DispatchQueue.main.async{
            self.testResult = test(mail: mx, classifier: model)
            if self.testResult == .FamSpam {
                self.title = "⚠️ False ➕"
            }
            if self.testResult == .SpamSpam {
                self.title = "\(spamEmoji) Spam"
            }
            if self.testResult == .SpamFam {
                self.title = "⚠️ False ➖"
            }
            if self.testResult == .FamFam {
                self.title = "\(famEmoji) Fam"
            }
            // print(self.title)
        }
        return Group {
            // Range Operator
            if (self.testMailsMaxID - 3)...self.testMailsMaxID ~= mx.id {
                MailView(size: self.cardDim, mail: mx, mails: self.$testMails, dim: self.frame, stats: self.stats, result: self.testResult)
                    .offset(x: 0, y: self.getCardOffset(mails: self.testMails, id: mx.id))
                    .animation(.spring())
            }
        }
    }
    
    func congrats() -> some View {
        DispatchQueue.main.async{
            if self.testMails.count == 0 {
                self.stats = .testingDone
                self.title = "🧪 Testing Done"
                self.moveCongratsHeight = self.cardDim.height * 0.5
            }
        }
        return VStack{
            HStack{
                Text("🎉").font(.custom("HelveticaNeue-ThinItalic", size: 64))
                Spacer()
                Text("🎊").font(.custom("HelveticaNeue-ThinItalic", size: 64))
                Spacer()
                Text("🎉").font(.custom("HelveticaNeue-ThinItalic", size: 64)).rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }.padding(.all)
                Text("🏆").font(.custom("HelveticaNeue-ThinItalic", size: 64))
        }.frame(width: self.cardDim.width, height: self.cardDim.height - self.moveCongratsHeight)
        .animation(.spring())
    }
    
    public var body: some View {
        GeometryReader { geometry in
        ZStack {
            self.setDims(geometry)
            LinearGradient(gradient: Gradient(colors: [Color.swiftspamBG1, Color.swiftspamBG2]), startPoint: UnitPoint(x: 1, y: 1), endPoint: UnitPoint(x: 0, y: 0))
                .edgesIgnoringSafeArea(.all)

            VStack{
            //Header
                Text(self.title)
                .font(.custom("HelveticaNeue-Thin", size: headingSize))
                .foregroundColor(.black)
                .padding(.vertical)
                
                ZStack{
                    // Training Emails
                    if self.stats == .start{
                        self.interval()
                        ForEach(self.mails, id: \.self) { mail in
                            self.trainingEmails(mail)
                        }
                    }
                    
                    // Training is done, click card to continue
                    if self.stats == .trainingDone {
                        self.intervalCard
                    }
                    
                    // Testing and classification starts now. NOTE, this autoswipes the card for you.
                    if self.stats == .intervalDone {
                        self.congrats()
                        ForEach(self.testMails, id: \.self) { mail in
                            self.testEmails(mail)
                        }
                    }
                    
                    // Congratulations, here is your trophy.
                    if self.stats == .testingDone {
                        self.congrats()
                    }
                }

                Spacer()
            }
        }
    }
    }
    
    private var intervalCard: some View {
        Group{
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Text("🥇")
                        .font(.custom("HelveticaNeue-Thin", size: iconSize))
                        .padding(.all)
                    Spacer()
                }
                Spacer()
            }.background(LinearGradient(gradient: Gradient(colors: [Color.swiftspamIntCardBG1, Color.swiftspamIntCardBG2]), startPoint: UnitPoint(x: 1, y: 1), endPoint: UnitPoint(x: 0, y: 0)))
            .frame(width: self.cardDim.width, height: self.cardDim.height)
            .cornerRadius(25)
            .gesture( TapGesture(count: 1)
                    .onEnded { _ in
                    self.startTesting = true
                    self.stats = .intervalDone
                })
        }.shadow(color: Color(.sRGB, white: 0, opacity: 0.10), radius: 7, x: 5, y: 5)
    }
}


struct MailView: View {
    // States
    var size: CGSize
    var mail: Mail
    @Binding var mails: [Mail]
    @State private var spamOrHam: SpamFam = .none
    var dim: CGSize
    var stats: Status
    var result: Results
    
    @State private var offset: CGSize = .zero
    @State private var toggleInfo = false
    
    @GestureState var isSelected = false
    @State var isDeleted = false
    
    var swipe: some Gesture{
        LongPressGesture()
            .updating($isSelected) { value, state, _ in
                    state = value
                }.simultaneously(with: DragGesture()
                .onChanged {
                    self.offset = $0.translation
                    if $0.translation.width / self.dim.width >= flickRatio{
                        self.spamOrHam = .fam
                    } else if $0.translation.width / self.dim.width <= -flickRatio{
                        self.spamOrHam = .spam
                    } else {
                        self.spamOrHam = .none
                    }
                }
                .onEnded { v in withAnimation {
                    if abs(v.translation.width/self.dim.width) > flickRatio{
                        // Add mail data to the list
                        if self.spamOrHam == .fam {
                            addFam(fam: &famBoy, mail: self.mail)
                        } else if self.spamOrHam == .spam {
                            addSpam(spam: &spamBoy, mail: self.mail)
                        }
                        self.mails.removeAll { $0.id == self.mail.id }
                    } else{
                        self.offset = .zero
                        self.spamOrHam = .none
                    }
                }
            }
        )
    }


    var autoSwipe: some Gesture{
        LongPressGesture( minimumDuration: 0.75, maximumDistance: 10)
            .updating($isSelected) { value, state, _ in
                    self.isDeleted = false
                    state = value
                }.onChanged {_ in
                    if self.result == .FamSpam || self.result == .SpamSpam {
                        self.spamOrHam = .spam
                        self.offset.width = self.dim.width * -flickRatio
                    } else if self.result == .SpamFam || self.result == .FamFam {
                        self.spamOrHam = .fam
                        self.offset.width = self.dim.width * flickRatio
                    }
                    self.isDeleted = true
                }
                .onEnded {_ in
                    self.mails.removeAll { $0.id == self.mail.id }
                }
    }

    private func checkDelete() -> some View{
        DispatchQueue.main.async{
            if self.isDeleted && !self.isSelected {
                self.mails.removeAll { $0.id == self.mail.id }
            }
        }
        return EmptyView()
    }

    private func infoButton(_ desc: String) -> some View{
        return Button(action : {
                self.toggleInfo.toggle()
            }){
                Text(desc) // Button Text
                    .font(.custom("HelveticaNeue", size: contentSize))
                    .foregroundColor(Color.blue)
        }
    }

    private func mailObjects(_ desc: String, _ mailData: String) -> some View{
        return  HStack(alignment: .top, spacing: 5){
            if desc != "" {
            Text("\(desc): ")
                .font(.custom("HelveticaNeue-Bold", size: contentSize))
                .foregroundColor(textColor)
                .lineSpacing(1.2)
            }

            Text(mailData)
                .font(.custom("HelveticaNeue-Light", size: contentSize))
                .foregroundColor(textColor)
                .lineSpacing(1.2)

            Spacer()
        }
    }
    
    var body: some View {
        ZStack{
            if self.stats == .start{
                Group{
                    cardView
                    if self.toggleInfo {
                        // See Description here about current mail.
                        infoView
                    }
                    if self.spamOrHam == .fam{
                        // IT IS A FAMILIAR MAIL
                        famOverlay
                    } else if self.spamOrHam == .spam{
                        // BEGONE SPAMMER!
                        spamOverlay
                    }
                }.shadow(color: Color(.sRGB, white: 0, opacity: 0.10), radius: 7, x: 5, y: 5)
                .scaleEffect(self.isSelected ? 1.05 : 1)
                .opacity(self.isSelected ? 0.9 : 1)
                .offset(x: self.offset.width, y: self.offset.height)
                .rotationEffect(.degrees(Double(self.offset.width / dim.width) * 25), anchor: .bottom)
                .gesture(self.swipe)
                .animation(.interactiveSpring())
            } else {
                Group{
                    cardView
                    if self.toggleInfo {
                        // See Description here.
                        infoView
                    }
                    if self.spamOrHam == .fam{
                        // IT IS A FAMILIAR MAIL
                        famOverlay
                    } else if self.spamOrHam == .spam{
                        // BEGONE SPAMMER!
                        spamOverlay
                    }
                }.shadow(color: Color(.sRGB, white: 0, opacity: 0.10), radius: 7, x: 5, y: 5)
                .scaleEffect(self.isSelected ? 1.05 : 1)
                .opacity(self.isSelected ? 0.9 : 1)
                .offset(x: self.offset.width, y: self.offset.height)
                .rotationEffect(.degrees(Double(self.offset.width / dim.width) * 25), anchor: .bottom)
                .gesture(self.autoSwipe)
                .animation(.interactiveSpring())
                self.checkDelete()
            }
        }
    }
    
    private var cardView: some View{
                    VStack(alignment: .leading) {
                    // Subject Line
                    mailObjects("Subject", self.mail.subject)

                    // From
                    mailObjects("From", self.mail.from)

                    // To
                    mailObjects("To", self.mail.to)

                    // Body
                    mailObjects("", self.mail.body).padding(.top)

                    Spacer()

                    // info button
                    infoButton("Learn More")
                
            }.padding(self.size.height/20).padding(.top)
                .frame(width: self.size.width, height: self.size.height)
                .animation(.interactiveSpring())
                .background(LinearGradient(gradient: Gradient(colors: [Color.swiftspamCardBG1, Color.swiftspamCardBG2]), startPoint: UnitPoint(x: 1, y: 1), endPoint: UnitPoint(x: 0, y: 0)).edgesIgnoringSafeArea(.all))
                .cornerRadius(25)
    }

    private var infoView: some View{
        VStack(alignment: .leading){
            
            // Spam or Fam
            Text(self.mail.isSpam ? "\(spamEmoji) Spam" : "\(famEmoji) Fam" )
                .font(.custom("HelveticaNeue-Thin", size: headingSize))
                .foregroundColor(Color.white)
                .padding(.all)
            
            // Description
            HStack{
                Text(self.mail.description)
                    .font(.custom("HelveticaNeue-Light", size: contentSize))
                    .foregroundColor(Color.white)
                    .lineSpacing(1.2)
                Spacer()
            }
            
            Spacer()

            // Info Button
            infoButton("Read Mail")

        }.padding(self.size.height/20).padding(.top)
            .background(LinearGradient(gradient: Gradient(colors: [Color.swiftspamInfoBG1, Color.swiftspamInfoBG2]), startPoint: UnitPoint(x: 1, y: 1), endPoint: UnitPoint(x: 0, y: 0)).edgesIgnoringSafeArea(.all))
            .frame(width: self.size.width, height: self.size.height)
            .cornerRadius(25)
    }
    
    private var spamOverlay: some View{
        VStack{
            Spacer()
            HStack{
                Spacer()
                Text(spamEmoji)
                    .font(.custom("HelveticaNeue-Thin", size: iconSize))
                    .foregroundColor(Color.white)
                    .padding(.all)
                // Spacer()
            }
            Spacer()
        }.background(Color.red)
            .frame(width: self.size.width, height: self.size.height)
            .cornerRadius(25)
            .opacity(0.85)
    }
    
    private var famOverlay: some View{
        VStack{
            Spacer()
            HStack{
                // Spacer()
                Text(famEmoji)
                    .font(.custom("HelveticaNeue-Thin", size: iconSize))
                    .foregroundColor(Color.white)
                    .padding(.all)
                Spacer()
            }
            Spacer()
        }.background(Color.green)
            .frame(width: self.size.width, height: self.size.height)
            .cornerRadius(25)
            .opacity(0.85)
    }
}

public func setHosting(_ trData: [Mail], _ tsData: [Mail] ) -> UIHostingController<ContentView> {
    return UIHostingController(rootView: ContentView(mails: trData, testMails: tsData))
}
