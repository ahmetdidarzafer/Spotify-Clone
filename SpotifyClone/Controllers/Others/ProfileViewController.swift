
import UIKit
import SDWebImage
class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "cell")
        return tableView
    }()
    private var models = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profil"
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        view.backgroundColor = .systemBackground
        fetchProfile()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    private func fetchProfile() {
        APIManager.shared.getCurrentUserProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    self?.updateUI(with: model)
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    self?.failedToGetProfile()
                    break
                }
            }
            
        }
    }
    private func updateUI(with model: UserProfile) {
        tableView.isHidden = false
        //Configure table models
        models.append("İsim: \(model.display_name)")
        models.append("Email: \(model.email)")
        models.append("Kullanıcı ID: \(model.id)")
        models.append("Plan: \(model.product)")
        createTableHeader(with: model.images.first?.url)
        tableView.reloadData()
    }
    private func createTableHeader(with string: String?) {
        guard let urlString = string, let url = URL(string: urlString) else { return }
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.width / 1.5))
        let imageSize: CGFloat = headerView.heigth / 2
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        headerView.addSubview(imageView)
        imageView.center = headerView.center
        imageView.sd_setImage(with: url)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageSize / 2
        tableView.tableHeaderView = headerView
    }
    private func failedToGetProfile() {
        let label = UILabel(frame: .zero)
        label.text = "Profil yüklenemedi"
        label.sizeToFit()
        label.textColor = .secondaryLabel
        view.addSubview(label)
        label.center = view.center
    }
    
    // MARK: - Table View
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = models[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }


}
