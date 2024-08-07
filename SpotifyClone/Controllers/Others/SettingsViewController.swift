
import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private var sections = [Section]()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ayarlar"
        configureModels()
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }
    private func configureModels() {
        sections.append(Section(title: "Profil", options: [Option(title: "Profilini Görüntüle", handler: { [weak self] in
            DispatchQueue.main.async {
                self?.viewProfile()
            }
            
        })]))
        
        sections.append(Section(title: "Hesap", options: [Option(title: "Çıkış Yap", handler: { [weak self] in
            DispatchQueue.main.async {
                self?.signOutTapped()
            }
            
        })]))
                        
    }
    private func signOutTapped() {
        let actionSheet = UIAlertController(title: "Çıkış Yap", message: "Çıkış Yapmak İstiyor musun?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Vazgeç", style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Çıkış Yap", style: .destructive, handler: { _ in
            AuthManager.shared.signOut { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        let navC = UINavigationController(rootViewController: WelcomeViewController())
                        navC.navigationBar.prefersLargeTitles = true
                        navC.modalPresentationStyle = .fullScreen
                        self?.present(navC, animated: true, completion: {
                            self?.navigationController?.popToRootViewController(animated: true)
                        })
                        
                    }
                }
            }
        }))
        present(actionSheet, animated: true)
    }
    
    private func viewProfile() {
        let vc = ProfileViewController()
        vc.title = "Profile"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
                        
                         
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = sections[indexPath.section].options[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = model.title
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let model = sections[section]
        return model.title
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = sections[indexPath.section].options[indexPath.row]
        model.handler()
    }
    
 
  
    
    
}
